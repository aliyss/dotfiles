{ pkgs, nimPackages, tridactyl-native-messenger, ... }:

{
  home.file.".mozilla/native-messaging-hosts/tridactyl.json".text =
    let tridactyl = pkgs.tridactyl-native;
    in builtins.toJSON {
      name = "tridactyl";
      description = "Tridactyl native command handler";
      path = "${tridactyl}/bin/native_main";
      type = "stdio";

      allowed_extensions = [
        "tridactyl.vim@cmcaine.co.uk"
        "tridactyl.vim.betas@cmcaine.co.uk"
        "tridactyl.vim.betas.nonewtab@cmcaine.co.uk"
      ];
    };

  xdg.configFile."tridactyl/tridactylrc".text = ''
    colourscheme --url https://raw.githubusercontent.com/aliyss/dotfiles/master/tridactyl/aliyss.css aliyss

    set newtab about:newtab
    set smoothscroll true
    set editorcmd emacsclient -a \"\" -c -e '(progn (find-file "%f") (forward-line (1- %l)) (forward-char %c))'

    unbind --mode=normal b
    bind bb tabprev
    bind bn tabnext
    bind bc tabclose
    bind be fillcmdline tabclose
    bind bj fillcmdline taball

    unbind --mode=normal t
    bind tt back
    bind tn forward
    bind td tabdetach
    bind be fillcmdline tabclose
    bind bj fillcmdline taball

    unbind --mode=normal w
    bind ww fillcmdline winopen
    bind wm fillcmdline winmerge
    bind wc winclose
    bind we fillcmdline winclose

    bind e fillcmdline open

    blacklistadd monkeytype.com
    blacklistadd remotedesktop.google.com
  '';

}
