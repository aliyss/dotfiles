// config.js - a minimal bootstrap to restore Ctrl+Shift+B for Library (switched with toggleBookmarksToolbar at Ctrl+Shift+O) - by AveYo
// create in Firefox install directory - for windows = C:\Program Files\Mozilla Firefox\
// must also create C:\Program Files\Mozilla Firefox\defaults\pref\config-prefs.js

//
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
              window.gBrowser.tabContainer.advanceSelectedTab(-1, true);
            },
            n: () => {
              window.console.log("Tab Forward");
              window.gBrowser.tabContainer.advanceSelectedTab(1, true);
            },
          },
        };

        // CONFIG HELPERS
        var currentConfig = keybindingConfig;

        function loopOverKeybindingConfig(event, config = currentConfig) {
          if (config[event.key] && typeof config[event.key] !== "function") {
            currentConfig = config[event.key];
            return;
          } else if (config[event.key]) {
            config[event.key]();
          }

          currentConfig = keybindingConfig;
          window.console.log("Reset Keybinding Current Config");
        }

        // EVENT LISTENERS

        window.document.addEventListener("keydown", function (event) {
          window.console.log(event.target);
          // loopOverKeybindingConfig(event);
        });

        window.document.addEventListener("oninput", function (event) {
          window.console.log("input");
          // window.console.log(event.target);
          // loopOverKeybindingConfig(event);
        });
      }
    }
  },
};
if (!Services.appinfo.inSafeMode) {
  new ConfigJS();
}
