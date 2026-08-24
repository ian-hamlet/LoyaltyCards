# CRASH-001: Native EXC_BAD_ACCESS Crash Printing Stamp Setup QR Code

**Source:** Apple App Store Connect - Crash Report (App Review, physical device flagged as the reproduction environment)
**Status:** ✅ FIXED and LIVE - v2.0.2+21 (guard added to the confirmed crash site, then audited and applied to 5 other call sites sharing the identical gap) passed App Review and shipped to the App Store 2026-08-10. Ongoing verification is now via App Store Connect crash monitoring rather than review re-verification - see Follow-Up Recommendation 5 below.
**Priority:** CRITICAL
**Affected App:** Supplier App (`com.ianhamlet.loyaltycards.supplierApp`)
**Affected Version:** 2.0.0+19
**Screen/Feature:** Stamp Setup screen (Simple/Express Mode) - "Generate Stamp QR Code" - **Print** button (confirmed crash site). A follow-up self-audit (prompted by App Review's report not having been caught across several prior code reviews) found the same unguarded pattern on 5 more buttons across 2 sibling screens - see "Wider Audit" below.
**File:** `source/supplier_app/lib/screens/supplier/supplier_stamp_card.dart` (`_printToken`, line ~413)

---

## Crash Report Summary

| Field | Value |
|---|---|
| Incident ID | 22B5EB6D-ED03-4842-BB97-FF586A23324B |
| Date | 2026-08-05 09:35:42 -0700 |
| Device | iPad15,3 |
| OS | iPhone OS 26.6 (23G71) |
| Build | 2.0.0 (19) |
| Exception | `EXC_BAD_ACCESS` / `SIGSEGV`, `KERN_INVALID_ADDRESS at 0x0000000000000010` |
| Faulting thread | #28 (background thread spawned by UIKit, not a Flutter/Dart isolate thread) |

### Faulting thread backtrace

```
CGPDFDocumentGetNumberOfPages                                        (CoreGraphics)
PrintJob.numberOfPages.getter                                        (printing.framework, pub.dev "printing" plugin v5.15.0)
@objc PrintJob.numberOfPages.getter
-[UIPrintPageRenderer _numberOfPages]
-[UIPrintInteractionController _updatePageCount]
__47-[UIPrintPreviewViewController updatePageCount]_block_invoke
__NSThread__start__
_pthread_start
thread_start
```

`far = 0x10`, `esr` = Data Abort, byte read, translation fault - i.e. a read at address `0x10`, the signature of dereferencing a `nil`/dangling `CGPDFDocumentRef` plus a small internal-field offset. Every frame on the faulting thread is native (Apple UIKit/CoreGraphics or the third-party `printing` plugin) - there is no Dart or app code on this thread, confirming the fault happens entirely inside the OS's native print-preview subsystem.

---

## Definition of the Problem

Tapping **Print** on the Stamp Setup screen calls `Printing.layoutPdf(...)` (from the `printing` package, v5.15.0), which hands the generated backup/token PDF to iOS's native **Print Preview** UI (`UIPrintInteractionController` / `UIPrintPreviewViewController`). While that preview is opening, iOS spins up its own background thread to ask the plugin's native `PrintJob` object how many pages the document has (`numberOfPages` -> `CGPDFDocumentGetNumberOfPages`). If a second print job is started (or the first job's native state is still being set up) while that page-count query runs, the query can observe a `CGPDFDocumentRef` that is `nil` or in a half-initialized state, and `CGPDFDocumentGetNumberOfPages` crashes reading through it.

### Root cause

`_printToken()` in `supplier_stamp_card.dart` is bound directly to the **Print** button's `onPressed` with **no re-entrancy guard**:

```dart
// supplier_stamp_card.dart (before fix)
Expanded(
  child: OutlinedButton.icon(
    onPressed: _printToken,   // no busy-state check - stays tappable mid-flight
    icon: const Icon(Icons.print),
    label: const Text('Print'),
    ...
  ),
),
```

Unlike the neighboring **Generate QR Code** button, which already disables itself and shows a spinner via `_isProcessing` while its async work runs, the **Print** button has no equivalent state. A user can tap **Print** more than once (e.g. a double-tap, easy to do on the 11" iPad in the crash report) before the first `Printing.layoutPdf()` call's native print-preview UI finishes initializing, firing a second concurrent native print job. That race is the most plausible trigger for the native page-count query observing an invalid `CGPDFDocumentRef`.

Notably, `printing` 5.15.0 (the version already in use, and the latest published release) lists "fix thread issues on iOS/macOS printing plugin" and "filtering of redundant pdf layout requests" in its changelog - i.e. the plugin author has already tried to harden this exact class of race. That this still crashed under iOS 26.6 suggests either that mitigation doesn't cover this specific `UIPrintPreviewViewController.updatePageCount` code path, or iOS 26's print-preview internals expose the race differently. Either way, the crash is inside Apple/UIKit's interaction with the third-party plugin's native layer, which we cannot patch directly - but we can close off the app-side trigger.

### Contributing factor (in our control)

The same unguarded pattern (`onPressed`/`onTap` bound directly to an async method that calls into a native plugin - `Printing.layoutPdf()` or `Share.shareXFiles()` - with no busy-state check) also existed on two sibling screens. Only the Stamp Setup screen's Print button is confirmed as the crash site from this report; the rest were found by auditing every call site of `BackupStorageService`'s print/share/save methods for the same gap (see "Wider Audit" below) and are now fixed alongside it.

---

## Fix Applied

Added a busy-state guard to the Stamp Setup screen's print flow, mirroring the existing `_isProcessing` pattern used for the Generate button:
- New `_isPrinting` state flag, set while `_printToken()`'s async work is in flight.
- `_printToken()` returns immediately (no-op) if a print is already in progress.
- The **Print** button is disabled and shows an inline spinner while `_isPrinting` is true, so the native print job cannot be re-entered by a fast double-tap.

This does not fix the underlying native plugin behavior (out of our control), but it removes the app-side trigger identified as the most plausible cause of the concurrent print-job race.

A regression test (`test/screens/supplier_stamp_card_test.dart`) intercepts the `printing` plugin's method channel (`net.nfet.printing`) to count native print-job starts, then calls the print handler twice back-to-back. Verified red/green manually: with the guard removed, two concurrent native print jobs start (the crash's precondition); with the guard in place, only one does.

## Wider Audit and Fix (2026-08-05)

Prompted by the observation that this pattern survived several prior code reviews with different personas, every call site of `BackupStorageService`'s print/share/save methods (the only paths that reach the `printing`/`share_plus` native plugins) was audited for the same missing-guard shape. Five more instances of the identical gap were found and fixed the same way (a per-action busy-state bool, checked at the top of the handler and used to disable the button / show an inline spinner):

| Screen | Button | Method | Native call | Guard added |
|---|---|---|---|---|
| `recovery_backup_screen.dart` | Print Backup | `_printBackup` | `Printing.layoutPdf` | `_isPrinting` |
| `recovery_backup_screen.dart` | Share via Email | `_shareViaEmail` | `Share.shareXFiles` | `_isSharingEmail` |
| `recovery_backup_screen.dart` | Save to Files | `_saveToFiles` | file write + `Share.shareXFiles` | `_isSavingToFiles` |
| `supplier_issue_card.dart` | Print | `_printToken` | `Printing.layoutPdf` | `_isPrinting` |
| `supplier_issue_card.dart` | Share | `_shareToken` | `Share.shareXFiles` | `_isSharing` |
| `supplier_stamp_card.dart` | Share QR | `_shareToken` | `Share.shareXFiles` | `_isSharing` (added alongside the original `_isPrinting` fix - the Share button on this same screen had been missed the first time) |

The two `Printing.layoutPdf` call sites (Print Backup, Print on the Issue Card screen) carry the same native crash risk as the original Stamp Setup finding. The four `Share.shareXFiles` call sites are a different native subsystem with no confirmed crash report against them, but shared the identical missing-guard shape (double-tap could open two share sheets or double-write a file) and are fixed for consistency and defense-in-depth.

Each screen also gained a `@visibleForTesting` `*ForTesting()` forwarder to its guarded handler (following the existing convention from `SupplierRedeemCard`), so the same double-tap-simulation regression test approach used for the Stamp Setup screen could be extended to all five without depending on real gesture/frame timing.

### Regression tests added for all 6 locations

- `test/screens/supplier_stamp_card_test.dart` - Print (original) + Share QR
- `test/screens/supplier_issue_card_test.dart` - Print + Share (new file)
- `test/screens/recovery_backup_screen_test.dart` - Print Backup + Share via Email + Save to Files (new file)

Each test intercepts the relevant native method channel (`net.nfet.printing` for print, `dev.fluttercommunity.plus/share` for share) to count native calls, fires the guarded handler twice back-to-back, and was verified red (native call fires twice with the guard temporarily removed) before green (fires once with the guard restored).

Two non-obvious issues surfaced while writing these and are worth flagging for anyone extending this pattern:

1. **`Printing.layoutPdf()`'s Future only resolves once the mocked channel handler also simulates the native `onCompleted` callback** (`printing`'s job-based protocol) - otherwise the guarded call hangs forever and the test times out.
2. **Never call `expect()` inside a `tester.runAsync()` callback.** A failure there is recorded via the test binding's single pending-exception slot rather than thrown normally - and on `recovery_backup_screen.dart` specifically, a *later* unrelated exception (a pre-existing, harmless `ListTile`/`DecoratedBox` background-color warning this screen already triggers) silently overwrote that slot before the real failure was ever reported, letting a fully-removed guard pass the test undetected. Confirmed by hand with a deliberately-broken assertion. Fix: capture the value inside `runAsync`, `expect()` it outside, in the normal test-body zone.

Also confirmed: `BackupStorageService.saveToFiles()` throws synchronously on any platform that isn't iOS or Android, which is what a `flutter test` host always is - so its Save to Files test can't observe the native `Share.shareXFiles` call count the way the other five can. Its guard is instead verified via a direct `@visibleForTesting` getter on the busy-state flag rather than through native-call counting.

Full suite (74 tests) passes, confirmed stable across repeated full-suite runs.

## Follow-Up Fix: Validate PDF Bytes Before Handing Off to the Native Plugin (2026-08-06)

Apple's App Review rejection notes for this crash described the trigger simply as "Tapping on 'Print' caused the app to crash" (device: iPad Air 11-inch (M3), iPadOS 26.6) - a plain-language description that doesn't distinguish a single tap from a fast double-tap, so it neither confirms nor rules out the double-tap race above. Reviewing for other single-tap-reachable causes of the same crash signature found one real, previously-unaddressed gap: every `Printing.layoutPdf()` call's `onLayout` callback handed `pdf.save()`'s result straight to the native plugin with **no validation at all**:

```dart
onLayout: (PdfPageFormat format) async => pdf.save(),
```

If `pdf.save()` ever produced empty or malformed bytes (a rendering edge case, a truncated write), the native plugin would still try to construct a `CGPDFDocument` from it - a second, single-tap-reachable path to the same `EXC_BAD_ACCESS` crash that the re-entrancy guard above doesn't cover (that guard only stops a *second concurrent* call, not a first call with bad data).

**Fix:** added `BackupStorageService._isValidPdfBytes()` - checks the bytes are non-empty and start with the mandatory `%PDF-` header (PDF spec section 7.5.2) - and `_generateValidatedPdfBytes()`, which calls `pdf.save()` then validates before returning. All three `onLayout` callbacks (`printBackup`, `printSimpleToken`, `printIssueCard`) now go through this instead of calling `pdf.save()` directly. An invalid PDF now throws a caught Dart exception, surfaced to the user as an ordinary "Failed to print" error, instead of crossing into native code as bad data.

**Testing:** the validation logic was pulled out as a pure function (`isValidPdfBytesForTesting`, bytes in, bool out) specifically so the reject path is testable without needing to coax `pw.Document.save()` itself into producing bad output. Added 4 tests in `backup_storage_service_test.dart` (accepts valid header, rejects empty bytes, rejects too-short bytes, rejects wrong header) - verified red (all 3 reject cases fail) with the check temporarily stubbed to always return true, then green with it restored. Full suite (78 tests) passes, confirmed stable across repeated runs.

This does not address the possibility of an app-backgrounded-mid-generation interruption, or a genuine iOS 26/M3-specific bug in the plugin's own native layer unrelated to anything on the Dart side - both remain unaddressable from this codebase; see recommendations 3-5 below.

## Final Verification: Every Print/Save Instance, by Screen (2026-08-06)

Confirmed by direct search of the codebase, not from memory, that both fixes (the re-entrancy guard and the PDF-bytes validation) are applied everywhere they need to be, with no stragglers:

| Screen | Button | Method | Re-entrancy guard (double-tap fix) | PDF-bytes validation (single-tap fix) | Regression test |
|---|---|---|---|---|---|
| `recovery_backup_screen.dart` | Print Backup | `printBackup()` | ✅ `_isPrinting` | ✅ via `_generateValidatedPdfBytes` | `recovery_backup_screen_test.dart` |
| `supplier_stamp_card.dart` (Stamp Setup / Express Mode) | Print | `printSimpleToken()` | ✅ `_isPrinting` | ✅ via `_generateValidatedPdfBytes` | `supplier_stamp_card_test.dart` |
| `supplier_issue_card.dart` (Issue Card) | Print | `printIssueCard()` | ✅ `_isPrinting` | ✅ via `_generateValidatedPdfBytes` | `supplier_issue_card_test.dart` |

Verification commands and results:

```
$ grep -rn "Printing.layoutPdf" source/supplier_app/lib source/customer_app/lib
```
Returns exactly the 3 call sites above (`backup_storage_service.dart` lines 50, 616, 1025) - no others exist in either app.

```
$ grep -rn "pdf\.save()" source/supplier_app/lib source/customer_app/lib
```
Returns exactly one call - the one inside `_generateValidatedPdfBytes` itself. No path exists where a `pw.Document` is saved and handed to the native plugin without going through validation first.

**Scope note:** the *Save to Files* button on `recovery_backup_screen.dart` is a different operation - it writes a PNG directly to disk and never touches `Printing.layoutPdf` or `pdf.save()`, so the PDF-bytes validation fix doesn't apply there (there's nothing PDF-shaped to validate). It does have the re-entrancy guard (`_isSavingToFiles`), from the earlier round of fixes, but was never in scope for the PDF-specific gap closed above.

**Share button comparison:** considered whether the three Share buttons (which share the same re-entrancy-guard pattern) have an equivalent single-tap "bad data reaches native code unchecked" gap. Concluded no - `share_plus`'s native call (`channel.invokeMethod('share', paramsMap)`) is a single one-shot request handing the OS a file path; unlike `CGPDFDocumentGetNumberOfPages`, it doesn't parse the file's internal structure on a background thread to compute something like a page count, so there's no equivalent native-parse-of-malformed-data mechanism for it to crash on. No corresponding fix was needed on the Share side.

## Decision: Resubmitting Without Hardware Reproduction (2026-08-10)

The crash could not be reproduced locally on any available simulator or device, and no iPad Air 11" (M3) - the exact model in the crash report - is available to test against directly. Both identified single-tap and double-tap trigger paths are fixed and individually regression-tested (see "Final Verification" table above), but neither fix has been confirmed against the real crash signature on matching hardware, since the race is timing-dependent and didn't reproduce even on other iPad hardware/simulators.

Decision: proceed to App Review resubmission on this basis rather than delay further trying to source M3 hardware. Recommendation 3 below (switch `Printing.layoutPdf` to `Printing.sharePdf`/`share_plus`, which would avoid the crashing native code path - `UIPrintInteractionController`/`CGPDFDocumentGetNumberOfPages` - entirely rather than just guarding against the two theorized triggers) was considered as a lower-risk alternative but not applied for this submission, since it changes the print UX (native print preview vs. share sheet) and the two applied fixes already close every code-reachable path identified during root-cause analysis. Recommendation 5 (monitor App Store Connect for recurrence after this ships) is now the primary remaining verification signal.

## Follow-Up Recommendations (not part of this change)

1. ~~Apply the same guard to `recovery_backup_screen.dart` and `supplier_issue_card.dart`~~ - done, see "Wider Audit" above.
2. ~~Add regression tests for the five newly-guarded call sites~~ - done, see "Regression tests added for all 6 locations" above.
3. Evaluate replacing `Printing.layoutPdf` (which drives the interactive native Print Preview / page-count subsystem where this crash occurs) with `Printing.sharePdf` or `share_plus` for these QR-backup flows, since the user's end goal is just "get this PDF to a printer," and the share-sheet path does not exercise the crashing code path at all.
4. File an issue upstream against `DavBfr/dart_pdf` (the `printing` package) with this exact stack trace, since all crashing frames are inside the plugin/UIKit/CoreGraphics, not app code.
5. Monitor App Store Connect for recurrence/volume after this fix ships, to confirm whether the double-tap race was the sole trigger.
