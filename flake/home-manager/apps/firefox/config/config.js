// config.js - a minimal bootstrap to restore Ctrl+Shift+B for Library (switched with toggleBookmarksToolbar at Ctrl+Shift+O) - by AveYo
// create in Firefox install directory - for windows = C:\Program Files\Mozilla Firefox\
// must also create C:\Program Files\Mozilla Firefox\defaults\pref\config-prefs.js

try {
    let { classes: Cc, interfaces: Ci, manager: Cm } = Components;
    const { Services } = Components.utils.import(
        "resource://gre/modules/Services.jsm",
    );
    const myKeyChanges = [
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
    function ConfigJS() {
        Services.obs.addObserver(this, "chrome-document-global-created", false);
    }
    ConfigJS.prototype = {
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
                    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                    let mozilla =
                        window.document.getElementById("manBookmarkKb");
                    mozilla.setAttribute(
                        "oncommand",
                        "BookmarkingUI.toggleBookmarksToolbar('shortcut');",
                    );
                    mozilla.removeAttribute("command");
                    let arse = window.document.getElementById(
                        "viewBookmarksToolbarKb",
                    );
                    arse.setAttribute("command", "Browser:ShowAllBookmarks");
                    arse.removeAttribute("oncommand");
                    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                    // CONFIG NATIVE KEYBINDINGS
                    var keybindingConfig = {
                        t: {
                            t: () => {
                                window.console.log("Browsed Back");
                                window.BrowserBack();
                            },
                            n: () => {
                                window.console.log("Browsed Forward");
                                window.BrowserForward();
                            },
                        },
                        b: {
                            b: () => {
                                window.console.log("Tab Back");
                                window.gBrowser.tabContainer.advanceSelectedTab(
                                    -1,
                                    true,
                                );
                            },
                            n: () => {
                                window.console.log("Tab Forward");
                                window.gBrowser.tabContainer.advanceSelectedTab(
                                    1,
                                    true,
                                );
                            },
                        },
                    };
                    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                    // CONFIG HELPERS
                    var currentConfig = keybindingConfig;
                    function loopOverKeybindingConfig(
                        event,
                        config = currentConfig,
                    ) {
                        if (
                            config[event.key] &&
                            typeof config[event.key] !== "function"
                        ) {
                            currentConfig = config[event.key];
                            return;
                        } else if (config[event.key]) {
                            // config[event.key]();
                        }
                        currentConfig = keybindingConfig;
                        window.console.log("Reset Keybinding Current Config");
                    }
                    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                    window.document.addEventListener(
                        "keydown",
                        function (event) {
                            if (event.target.localName === "input") {
                                window.console.log(event.target);
                                return;
                            }
                            window.console.log(event.target);
                            loopOverKeybindingConfig(event);
                        },
                    );
                    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                    // for (var i = 0; i < myKeyChanges.length; i++) {
                    //     var menuitem = window.document.getElementById(
                    //         myKeyChanges[i].id,
                    //     );
                    //     if (menuitem) {
                    //         if (myKeyChanges[i].newkey.length == 1) {
                    //             menuitem.setAttribute(
                    //                 "accesskey",
                    //                 myKeyChanges[i].newkey,
                    //             );
                    //         }
                    //         if (myKeyChanges[i].newlabel.length > 0) {
                    //             menuitem.setAttribute(
                    //                 "label",
                    //                 myKeyChanges[i].newlabel,
                    //             );
                    //         }
                    //     }
                    // }
                    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                }
            }
        },
    };
    if (!Services.appinfo.inSafeMode) {
        new ConfigJS();
    }
} catch (ex) {}
