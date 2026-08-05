# CRASH-001: Native EXC_BAD_ACCESS Crash Printing Stamp Setup QR Code

**Source:** Apple App Store Connect - Crash Report (production, real user device)
**Status:** ✅ FIXED (guard added) - pending TestFlight/production verification
**Priority:** CRITICAL
**Affected App:** Supplier App (`com.ianhamlet.loyaltycards.supplierApp`)
**Affected Version:** 2.0.0+19
**Screen/Feature:** Stamp Setup screen (Simple/Express Mode) - "Generate Stamp QR Code" - **Print** button
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

The same unguarded pattern (`onPressed`/`onTap` bound directly to an async `Printing.layoutPdf()`-calling method, with no busy-state check) also exists on two sibling screens:
- `source/supplier_app/lib/screens/supplier/recovery_backup_screen.dart` (`_printBackup`, "Print Backup")
- `source/supplier_app/lib/screens/supplier/supplier_issue_card.dart` (`_printToken`, "Print")

Only the Stamp Setup screen's Print button is confirmed as the crash site from this report; the other two share the identical gap and are called out here for awareness, not fixed as part of this change.

---

## Fix Applied

Added a busy-state guard to the Stamp Setup screen's print flow, mirroring the existing `_isProcessing` pattern used for the Generate button:
- New `_isPrinting` state flag, set while `_printToken()`'s async work is in flight.
- `_printToken()` returns immediately (no-op) if a print is already in progress.
- The **Print** button is disabled and shows an inline spinner while `_isPrinting` is true, so the native print job cannot be re-entered by a fast double-tap.

This does not fix the underlying native plugin behavior (out of our control), but it removes the app-side trigger identified as the most plausible cause of the concurrent print-job race.

## Follow-Up Recommendations (not part of this change)

1. Apply the same guard to `recovery_backup_screen.dart` and `supplier_issue_card.dart`, which share the identical gap.
2. Evaluate replacing `Printing.layoutPdf` (which drives the interactive native Print Preview / page-count subsystem where this crash occurs) with `Printing.sharePdf` or `share_plus` for these QR-backup flows, since the user's end goal is just "get this PDF to a printer," and the share-sheet path does not exercise the crashing code path at all.
3. File an issue upstream against `DavBfr/dart_pdf` (the `printing` package) with this exact stack trace, since all crashing frames are inside the plugin/UIKit/CoreGraphics, not app code.
4. Monitor App Store Connect for recurrence/volume after this fix ships, to confirm whether the double-tap race was the sole trigger.
