{pkgs, ...}: let
  lolcrab =
    pkgs.rustPlatform.buildRustPackage
    rec {
      name = "lolcrab";
      pname = "lolcrab";

      src = pkgs.fetchFromGitHub {
        owner = "mazznoer";
        rev = "00c06cdd1089e3f9256a44e18f83667f76820fe1";
        repo = pname;
        sha256 = "1q40HQaM9ozv1v9QKdNCsJShyuP+tvV/YL+YEkN9/90=";
      };

      cargoLock = {
        lockFile = ./dependencies/lolcrab/Cargo.lock;
        outputHashes = {
          "colorgrad-0.7.0" = "sha256-FUoTeXQkMajZI+9VpoJNqDe/pjeUWXyQGiIr96uH6tg=";
          "csscolorparser-0.6.2" = "sha256-9HRS2Y+OJRYpzKMJ+ZdNHAHzuvDNMEcZZ4F+HAPpLhI=";
        };
      };
    };
  plugins = pkgs.vimPlugins // pkgs.callPackage ./neovim-plugins.nix {};
  externalPackages = pkgs.callPackage ./neovim-external.nix {};
in {
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    extraPackages = with pkgs;
      [
        eslint_d
        ripgrep
        ripgrep-all
        tailwindcss
        luajitPackages.luacheck
        luajitPackages.lua-lsp
        luajitPackages.lua-curl
        xclip
        wl-clipboard
        stylua
        basedpyright
        pylint
        pylyzer
        postgresql_16
        phpactor
        nodePackages.intelephense
        phpPackages.php-cs-fixer
        blade-formatter
        black
        isort
        vim-language-server
        alejandra
        prettierd
        nodePackages_latest.jsonlint
        python311Packages.pynvim
        rust-analyzer
        lolcrab
        nil
      ]
      ++ [
      ];
    extraLuaPackages = pkgs: [
      pkgs.lua-curl
      pkgs.xml2lua
      pkgs.mimetypes
      pkgs.nvim-nio
    ];
    plugins = with plugins; [
      {
        plugin = nvim-tmux-navigation;
        config = builtins.readFile ./neovim/plugins/tmux-navigator.lua;
        type = "lua";
      }
      nvim-ts-context-commentstring
      todo-comments-nvim
      {
        plugin = comment-nvim;
        config = builtins.readFile ./neovim/plugins/comment.lua;
        type = "lua";
      }
      nvim-web-devicons
      # {
      #   plugin = dashboard-nvim;
      #   config = builtins.readFile ./neovim/plugins/dashboard.lua;
      #   type = "lua";
      # }
      plenary-nvim
      {
        plugin = harpoon;
        config = builtins.readFile ./neovim/plugins/harpoon.lua;
        type = "lua";
      }
      {
        plugin = neo-tree-nvim;
        config = builtins.readFile ./neovim/plugins/neo-tree.lua;
        type = "lua";
      }
      {
        plugin = project-nvim;
        config = builtins.readFile ./neovim/plugins/project.lua;
        type = "lua";
      }
      ## Treesitter
      nvim-ts-autotag

      (nvim-treesitter.withPlugins (_:
        nvim-treesitter.allGrammars
        ++ [
          (pkgs.tree-sitter.buildGrammar {
            language = "just";
            version = "8af0aab";
            src = pkgs.fetchFromGitHub {
              owner = "IndianBoy42";
              repo = "tree-sitter-just";
              rev = "8af0aab79854aaf25b620a52c39485849922f766";
              sha256 = "sha256-hYKFidN3LHJg2NLM1EiJFki+0nqi1URnoLLPknUbFJY=";
            };
          })
          (pkgs.tree-sitter.buildGrammar {
            language = "blade";
            version = "dead019";
            src = pkgs.fetchgit {
              url = "https://github.com/EmranMR/tree-sitter-blade";
              rev = "dead019eeabe612da7fb325caf72fdc7c744d19a";
              sha256 = "sha256-RW6W6CqBQZfAC5C1aGg3GLi+xThh2e33l65++3+uhMw=";
            };
          })
        ]))
      {
        plugin = nvim-treesitter;
        config = builtins.readFile ./neovim/plugins/treesitter.lua;
        type = "lua";
      }
      ## SQL Grammar
      vim-dadbod
      vim-dadbod-ui
      vim-dadbod-completion
      ## Rest Client
      {
        plugin = git-rest-nvim;
        config = builtins.readFile ./neovim/plugins/modes/rest.lua;
        type = "lua";
      }
      ## OrgMode Grammar
      {
        plugin = orgmode;
        config = builtins.readFile ./neovim/plugins/modes/orgmode.lua;
        type = "lua";
      }
      ## CMP
      neodev-nvim
      cmp-buffer
      cmp-path
      cmp-nvim-lsp
      cmp_luasnip
      luasnip
      friendly-snippets
      lspkind-nvim
      {
        plugin = nvim-cmp;
        config = builtins.readFile ./neovim/plugins/cmp.lua;
        type = "lua";
      }
      blade-nav
      ## Autopairs
      {
        plugin = nvim-autopairs;
        config = builtins.readFile ./neovim/plugins/autopairs.lua;
        type = "lua";
      }
      ## LSP
      mason-lspconfig-nvim
      mason-tool-installer-nvim
      {
        plugin = mason-nvim;
        config = builtins.readFile ./neovim/plugins/lsp/mason.lua;
        type = "lua";
      }
      {
        plugin = nvim-lspconfig;
        config = builtins.readFile ./neovim/plugins/lsp/lspconfig.lua;
        type = "lua";
      }
      ## Formatting
      guess-indent-nvim
      {
        plugin = conform-nvim;
        config = builtins.readFile ./neovim/plugins/lsp/formatting.lua;
        type = "lua";
      }
      ## Lint
      {
        plugin = nvim-lint;
        config = builtins.readFile ./neovim/plugins/lsp/linting.lua;
        type = "lua";
      }
      ## Highlighting
      {
        plugin = wookayin-semshi;
        config = builtins.readFile ./neovim/plugins/lsp/highlighting.lua;
        type = "lua";
      }
      ## Errors
      {
        plugin = trouble;
        config = builtins.readFile ./neovim/plugins/trouble.lua;
        type = "lua";
      }
      ## Debugging
      direnv-vim
      {
        plugin = nvim-dap;
        config = builtins.readFile ./neovim/plugins/debugging/dap.lua;
        type = "lua";
      }
      nvim-nio
      {
        plugin = nvim-dap-ui;
        config = builtins.readFile ./neovim/plugins/debugging/dap-ui.lua;
        type = "lua";
      }
      ## Git
      {
        plugin = gitsigns-nvim;
        config = builtins.readFile ./neovim/plugins/git/gitsigns.lua;
        type = "lua";
      }
      ## LLM
      {
        plugin = copilot-vim;
        config = builtins.readFile ./neovim/plugins/llm/copilot.lua;
        type = "lua";
      }
      ## Telescope
      telescope-undo-nvim
      telescope-fzf-native-nvim
      {
        plugin = telescope-nvim;
        config = builtins.readFile ./neovim/plugins/telescope.lua;
        type = "lua";
      }
      ## Autosession
      # {
      #   plugin = auto-session;
      #   config = builtins.readFile ./neovim/plugins/autosession.lua;
      #   type = "lua";
      # }
      ## Themes
      {
        plugin = colorizer;
        config = builtins.readFile ./neovim/plugins/themes/colorizer.lua;
        type = "lua";
      }
      nyoom-oxocarbon
      {
        plugin = lualine-nvim;
        config = builtins.readFile ./neovim/plugins/themes/lualine.lua;
        type = "lua";
      }
      {
        plugin = ibl;
        config = builtins.readFile ./neovim/plugins/themes/ibl.lua;
        type = "lua";
      }
      ## Keybindings
      # {
      #   plugin = precognition;
      #   config = builtins.readFile ./neovim/plugins/keybindings/precognition.lua;
      #   type = "lua";
      # }
      {
        plugin = vim-be-good;
      }
      {
        plugin = hardtime-nvim;
        config = builtins.readFile ./neovim/plugins/keybindings/hardtime.lua;
        type = "lua";
      }
      {
        plugin = neoscroll-nvim;
        config = builtins.readFile ./neovim/plugins/keybindings/neoscroll.lua;
        type = "lua";
      }
      {
        plugin = which-key-nvim;
        config = builtins.readFile ./neovim/plugins/keybindings/which-key.lua;
        type = "lua";
      }
      {
        plugin = stay-in-place;
        config = builtins.readFile ./neovim/plugins/keybindings/stay-in-place.lua;
        type = "lua";
      }

      ## Activity Watch
      aw-watcher-vim

      ## Email
      notmuch-vim
      # himalaya-custom-vim
    ];
    extraLuaConfig = ''
      ${builtins.readFile ./neovim/options.lua}
      ${builtins.readFile ./neovim/colorscheme.lua}

      vim.opt.runtimepath:append("~/Projects/vim-himalaya-ui")
    '';
  };

  xdg.configFile."nvim/after/queries/html/injections.scm".text = ''
    ;; extends

    ; AlpineJS attributes
    (attribute
      (attribute_name) @_attr
        (#lua-match? @_attr "^x%-%l")
        (#not-any-of? @_attr "x-teleport" "x-ref" "x-transition")
      (quoted_attribute_value
        (attribute_value) @injection.content)
      (#set! injection.language "javascript"))

    ; Blade escaped JS attributes
    ; <x-foo ::bar="baz" />
    (element
      (_
        (tag_name) @_tag
          (#lua-match? @_tag "^x%-%l")
      (attribute
        (attribute_name) @_attr
          (#lua-match? @_attr "^::%l")
        (quoted_attribute_value
          (attribute_value) @injection.content)
        (#set! injection.language "javascript"))))

    ; Blade PHP attributes
    ; <x-foo :bar="$baz" />
    (element
      (_
        (tag_name) @_tag
          (#lua-match? @_tag "^x%-%l")
        (attribute
          (attribute_name) @_attr
            (#lua-match? @_attr "^:%l")
          (quoted_attribute_value
            (attribute_value) @injection.content)
          (#set! injection.language "php_only"))))
  '';

  xdg.configFile."nvim/after/queries/php/indents.scm".text = ''
    ;; extends

    [
      ; prevent double indent for `return new class ...`
      (return_statement
        (object_creation_expression))
      ; prevent double indent for `return function() { ... }`
      (return_statement
        (anonymous_function_creation_expression))
    ] @indent.dedent
  '';

  xdg.configFile."nvim/queries/blade/folds.scm".text = ''
    ((directive_start) @start
        (directive_end) @end.after
        (#set! role block))


    ((bracket_start) @start
        (bracket_end) @end
        (#set! role block))
  '';
  xdg.configFile."nvim/queries/blade/highlights.scm".text = ''
    (directive) @function
    (directive_start) @function
    (directive_end) @function
    (comment) @comment
    ((parameter) @include (#set! "priority" 110))
    ((php_only) @include (#set! "priority" 110))
    ((bracket_start) @function (#set! "priority" 120))
    ((bracket_end) @function (#set! "priority" 120))
    (keyword) @function
  '';
  xdg.configFile."nvim/queries/blade/injections.scm".text = ''
    ((text) @injection.content
        (#not-has-ancestor? @injection.content "envoy")
        (#set! injection.combined)
        (#set! injection.language php))

    ((text) @injection.content
        (#has-ancestor? @injection.content "envoy")
        (#set! injection.combined)
        (#set! injection.language bash))

    ((php_only) @injection.content
        (#set! injection.combined)
        (#set! injection.language php_only))

    ((parameter) @injection.content
        (#set! injection.language php_only))
  '';
  xdg.configFile."nvim/queries/sql/injections.scm".text = ''
    ; extends

    (assignment
      right: (literal) @injection.content
      (#offset! @injection.content 0 1 0 -1)
      (#set! injection.language "json")
    )
  '';
}
