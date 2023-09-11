/* Script for the Browser Console

	   NOTE: BEFORE RUNNING THIS SCRIPT, CHECK THIS SETTING:
	   Type or paste about:config into the address bar and press Enter
	   Click the button promising to be careful
	   In the search box paste devtools.chrome.enabled
	   If the preference is false, double-click it to toggle to true

	Paste this entire script into the command line at the bottom of the Browser Console (Windows: Ctrl+Shift+j)
	Then press Enter to run the script.
*/

(function () {
    // Define an array of key change objects (so far, only one)
    var myKeyChanges = [
        {
            id: "context-copylink",
            newkey: "a",
            newlabel: "Copy Link Location",
        },
        {
            id: "context-copyemail",
            newkey: "A",
            newlabel: "Copy Email Address",
        },
    ];
    // Current window
    for (var i = 0; i < myKeyChanges.length; i++) {
        var menuitem = gBrowser.ownerDocument.getElementById(
            myKeyChanges[i].id,
        );
        if (menuitem) {
            if (myKeyChanges[i].newkey.length == 1) {
                menuitem.setAttribute("accesskey", myKeyChanges[i].newkey);
            }
            if (myKeyChanges[i].newlabel.length > 0) {
                menuitem.setAttribute("label", myKeyChanges[i].newlabel);
            }
        }
    }
    // All future windows -- based largely on
    // https://www.reddit.com/r/firefox/comments/kilmm2/restore_ctrlshiftb_library_by_setting_configjs/
    var acceleratorUpdater = {
        observe: function (aSubject) {
            aSubject.addEventListener("DOMContentLoaded", this, { once: true });
        },
        handleEvent: function (aEvent) {
            let document = aEvent.originalTarget;
            let window = document.defaultView;
            let location = window.location;
            if (
                /^(chrome:(?!\/\/(global\/content\/commonDialog|browser\/content\/webext-panels)\.x?html)|about:(?!blank))/i.test(
                    location.href,
                )
            ) {
                if (window._gBrowser) {
                    for (var i = 0; i < myKeyChanges.length; i++) {
                        var menuitem = window.document.getElementById(
                            myKeyChanges[i].id,
                        );
                        if (menuitem) {
                            if (myKeyChanges[i].newkey.length == 1) {
                                menuitem.setAttribute(
                                    "accesskey",
                                    myKeyChanges[i].newkey,
                                );
                            }
                            if (myKeyChanges[i].newlabel.length > 0) {
                                menuitem.setAttribute(
                                    "label",
                                    myKeyChanges[i].newlabel,
                                );
                            }
                        }
                    }
                }
            }
        },
    };
    Services.obs.addObserver(
        acceleratorUpdater,
        "chrome-document-global-created",
        false,
    );
})();
