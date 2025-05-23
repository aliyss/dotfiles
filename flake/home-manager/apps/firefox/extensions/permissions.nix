{
  lib,
  pkgs,
  ...
}: let
  extensions = {
    "mal-sync" = {
      permissions = [
        "storage"
        "alarms"
        "webRequest"
        "webRequestBlocking"
        "declarativeNetRequestWithHostAccess"
        "notifications"

        "*://*.gogoanime3.cc/*"
        "*://*.anitaku.bz/*"
        "*://*.voiranime.com/*"
        "*://zonatmo.com/*"
        "*://animexin.top/*"
        "*://smotret-anime.org/catalog/*"
        "*://smotret-anime.online/catalog/*"
        "*://*.animeunity.so/anime/*"
        "*://flamecomics.me/*"
        "*://flamecomics.xyz/*"
        "*://hianime.nz/*"
        "*://hianime.mn/*"
        "*://hianime.sx/*"
        "*://animego.me/anime/*"
        "*://q1n.net/*"
        "*://scyllacomics.xyz/*"
        "*://vortexscans.org/*"
        "*://weebcentral.com/*"
        "*://anilib.me/*"
        "*://demo.kavitareader.com/*"
        "*://mangalib.org/*"
        "*://mangalib.me/*"
        "*://*.slashlib.me/*"
        "*://*.yaoilib.net/*"
        "*://aninexus.to/*"
        "*://*.jwplayerhls.com/*"
        "*://*.videzz.net/*"
        "*://geo.dailymotion.com/*"
        "*://smotret-anime.org/translations/embed/*"
        "*://smotret-anime.online/translations/embed/*"
        "*://*.s3embtaku.pro/*"
        "*://dood.li/e/*"
        "*://bethshouldercan.com/e/*"
        "*://sandratableother.com/e/*"
        "*://robertordercharacter.com/e/*"
        "*://omegadthree.com/*"
        "*://hlswish.com/e/*"
        "*://rogeriobetin.com/*"
        "*://nvlabs-fi-cdn.q9x.in/*"
        "*://oneupload.to/*"
        "*://player.vimeo.com/*"
        "*://fle-rvd0i9o8-moo.com/*"
        "*://dhtpre.com/*"
        "https://myanimelist.net/"
        "https://myanimelist.cdn-dena.com/"
        "https://cdn.myanimelist.net/"
        "https://kissanimelist.firebaseio.com/"
        "https://*.anilist.co/"
        "https://graphql.anilist.co/"
        "https://kitsu.io/"
        "https://media.kitsu.io/"
        "https://api.simkl.com/"
        "https://www.netflix.com/"
        "https://vrv.co/"
        "https://discover.hulu.com/"
        "https://www.primevideo.com/"
        "https://www.crunchyroll.com/"
        "https://api.malsync.moe/"
        "https://api.myanimelist.net/"
        "https://api.mangadex.org/"
        "https://shikimori.me/"
        "*://myanimelist.net/anime/*"
        "*://myanimelist.net/manga/*"
        "*://myanimelist.net/animelist/*"
        "*://myanimelist.net/mangalist/*"
        "*://myanimelist.net/anime.php?id=*"
        "*://myanimelist.net/manga.php?id=*"
        "*://myanimelist.net/character/*"
        "*://myanimelist.net/people/*"
        "*://myanimelist.net/search/*"
        "*://malsync.moe/mal/oauth*"
        "*://malsync.moe/anilist/oauth*"
        "*://malsync.moe/shikimori/oauth*"
        "*://anilist.co/*"
        "*://kitsu.io/*"
        "*://simkl.com/*"
        "*://malsync.moe/pwa*"
        "*://*.9anime.to/watch/*"
        "*://*.9anime.to/watch2gether/*"
        "*://*.9anime.ru/watch/*"
        "*://*.9anime.ru/watch2gether/*"
        "*://*.9anime.live/watch/*"
        "*://*.9anime.live/watch2gether/*"
        "*://*.9anime.one/watch/*"
        "*://*.9anime.one/watch2gether/*"
        "*://*.9anime.page/watch/*"
        "*://*.9anime.page/watch2gether/*"
        "*://*.9anime.video/watch/*"
        "*://*.9anime.video/watch2gether/*"
        "*://*.9anime.life/watch/*"
        "*://*.9anime.life/watch2gether/*"
        "*://*.9anime.love/watch/*"
        "*://*.9anime.love/watch2gether/*"
        "*://*.9anime.tv/watch/*"
        "*://*.9anime.tv/watch2gether/*"
        "*://*.9anime.app/watch/*"
        "*://*.9anime.app/watch2gether/*"
        "*://*.9anime.at/watch/*"
        "*://*.9anime.at/watch2gether/*"
        "*://*.9anime.bar/watch/*"
        "*://*.9anime.bar/watch2gether/*"
        "*://*.9anime.pw/watch/*"
        "*://*.9anime.pw/watch2gether/*"
        "*://*.9anime.cz/watch/*"
        "*://*.9anime.cz/watch2gether/*"
        "*://*.9anime.ws/watch/*"
        "*://*.9anime.ws/watch2gether/*"
        "*://*.9anime.id/watch/*"
        "*://*.9anime.id/watch2gether/*"
        "*://*.9anime.center/watch/*"
        "*://*.9anime.center/watch2gether/*"
        "*://*.9anime.club/watch/*"
        "*://*.9anime.club/watch2gether/*"
        "*://*.9anime.pl/watch/*"
        "*://*.9anime.pl/watch2gether/*"
        "*://*.9anime.gs/watch/*"
        "*://*.9anime.gs/watch2gether/*"
        "*://*.9anime.ph/watch/*"
        "*://*.9anime.ph/watch2gether/*"
        "*://*.aniwave.to/watch/*"
        "*://*.aniwave.to/watch2gether/*"
        "*://*.aniwave.bz/watch/*"
        "*://*.aniwave.bz/watch2gether/*"
        "*://*.aniwave.ws/watch/*"
        "*://*.aniwave.ws/watch2gether/*"
        "*://*.aniwave.vc/watch/*"
        "*://*.aniwave.vc/watch2gether/*"
        "*://*.aniwave.li/watch/*"
        "*://*.aniwave.li/watch2gether/*"
        "*://*.crunchyroll.com/*"
        "*://mangadex.org/*"
        "*://*.gogoanime.tv/*"
        "*://*.gogoanime.io/*"
        "*://*.gogoanime.in/*"
        "*://*.gogoanime.se/*"
        "*://*.gogoanime.sh/*"
        "*://*.gogoanime.video/*"
        "*://*.gogoanime.movie/*"
        "*://*.gogoanime.so/*"
        "*://*.gogoanime.ai/*"
        "*://*.gogoanime.vc/*"
        "*://*.gogoanime.pe/*"
        "*://*.gogoanime.wiki/*"
        "*://*.gogoanime.cm/*"
        "*://*.gogoanime.film/*"
        "*://*.gogoanime.fi/*"
        "*://*.gogoanime.gg/*"
        "*://*.gogoanime.sk/*"
        "*://*.gogoanime.lu/*"
        "*://*.gogoanime.tel/*"
        "*://*.gogoanime.ee/*"
        "*://*.gogoanime.dk/*"
        "*://*.gogoanime.ar/*"
        "*://*.gogoanime.bid/*"
        "*://*.gogoanimes.co/*"
        "*://*.animego.to/*"
        "*://*.gogoanime.gr/*"
        "*://*.gogoanime.llc/*"
        "*://*.gogoanime.cl/*"
        "*://*.gogoanime.hu/*"
        "*://*.gogoanime.vet/*"
        "*://*.gogoanimehd.to/*"
        "*://*.gogoanime3.net/*"
        "*://*.gogoanimehd.io/*"
        "*://*.anitaku.to/*"
        "*://*.anitaku.so/*"
        "*://*.gogoanime3.co/*"
        "*://*.www.turkanime.tv/video/*"
        "*://*.www.turkanime.tv/anime/*"
        "*://*.www.turkanime.net/video/*"
        "*://*.www.turkanime.net/anime/*"
        "*://*.www.turkanime.co/video/*"
        "*://*.www.turkanime.co/anime/*"
        "*://app.emby.media/*"
        "*://app.emby.tv/*"
        "*://app.plex.tv/*"
        "*://www.netflix.com/*"
        "*://animepahe.com/play/*"
        "*://animepahe.com/anime/*"
        "*://animepahe.ru/play/*"
        "*://animepahe.ru/anime/*"
        "*://animepahe.org/play/*"
        "*://animepahe.org/anime/*"
        "*://*.animeflv.net/anime/*"
        "*://*.animeflv.net/ver/*"
        "*://jkanime.net/*"
        "*://proxer.me/*"
        "*://proxer.net/*"
        "*://*.aniflix.tv/*"
        "*://*.aniflix.cc/*"
        "*://*.kaas.am/*"
        "*://*.kaas.ro/*"
        "*://*.kaas.to/*"
        "*://*.kickassanime.ro/*"
        "*://*.kickassanime.am/*"
        "*://*.kickassanimes.io/*"
        "*://*.kickassanime.mx/*"
        "*://shinden.pl/episode/*"
        "*://shinden.pl/series/*"
        "*://shinden.pl/titles/*"
        "*://shinden.pl/epek/*"
        "*://voiranime.com/*"
        "*://v2.voiranime.com/*"
        "*://v3.voiranime.com/*"
        "*://v4.voiranime.com/*"
        "*://v5.voiranime.com/*"
        "*://www.viz.com/*"
        "*://manganato.com/*"
        "*://readmanganato.com/*"
        "*://chapmanganato.com/*"
        "*://chapmanganato.to/*"
        "*://*.neko-sama.fr/*"
        "*://animecat.net/*"
        "*://www.animezone.pl/odcinki/*"
        "*://www.animezone.pl/odcinek/*"
        "*://www.animezone.pl/anime/*"
        "*://anime-odcinki.pl/anime/*"
        "*://serimanga.com/*"
        "*://mangadenizi.com/*"
        "*://*.mangadenizi.net/*"
        "*://moeclip.com/*"
        "*://mangalivre.net/*"
        "*://tmofans.com/*"
        "*://lectortmo.com/*"
        "*://visortmo.com/*"
        "*://gastronomiaporpaises.com/*"
        "*://releasingcars.com/*"
        "*://mundorecetascuriosas.com/*"
        "*://lupitaalosfogones.com/*"
        "*://cocinarporelmundo.com/*"
        "*://disfrutacocina.com/*"
        "*://recetascuriosas.com/*"
        "*://lacocinadelupita.com/*"
        "*://mynewsrecipes.com/*"
        "*://recipestravelworld.com/*"
        "*://recipestraveling.com/*"
        "*://recetaspaises.com/*"
        "*://worldrecipesu.com/*"
        "*://techinroll.com/*"
        "*://vsrecipes.com/*"
        "*://mygamesinfo.com/*"
        "*://gamesnk.com/*"
        "*://otakuworldgames.com/*"
        "*://animalcanine.com/*"
        "*://cook2love.com/*"
        "*://wtechnews.com/*"
        "*://animationforyou.com/*"
        "*://fanaticmanga.com/*"
        "*://mistermanga.com/*"
        "*://enginepassion.com/*"
        "*://motornk.com/*"
        "*://recipesnk.com/*"
        "*://panicmanga.com/*"
        "*://worldmangas.com/*"
        "*://anitoc.com/*"
        "*://cookerready.com/*"
        "*://cooker2love.com/*"
        "*://infopetworld.com/*"
        "*://infogames2you.com/*"
        "*://almtechnews.com/*"
        "*://animation2you.com/*"
        "*://recipesdo.com/*"
        "*://vgmotor.com/*"
        "*://myotakuinfo.com/*"
        "*://otakworld.com/*"
        "*://cookermania.com/*"
        "*://motorbakery.com/*"
        "*://recipesist.com/*"
        "*://motorpi.com/*"
        "*://dariusmotor.com/*"
        "*://recipesaniki.com/*"
        "*://cocinaconlupita.com/*"
        "*://recetasdelupita.com/*"
        "*://gamesxo.com/*"
        "*://fitfooders.com/*"
        "*://checkingcars.com/*"
        "*://keepfooding.com/*"
        "*://feelthecook.com/*"
        "*://recetchef.com/*"
        "*://motoroilblood.com/*"
        "*://anisurion.com/*"
        "*://recipescoaching.com/*"
        "*://anitirion.com/*"
        "*://cookernice.com/*"
        "*://animalsside.com/*"
        "*://paleomotor.com/*"
        "*://otakunice.com/*"
        "*://sucrecipes.com/*"
        "*://recetasviaje.com/*"
        "*://animalslegacy.com/*"
        "*://worldcuisineis.com/*"
        "*://eligeunnombre.com/*"
        "*://cyclingresolution.com/*"
        "*://comollamarle.com/*"
        "*://fashionandcomplements.com/*"
        "*://gamesnacion.com/*"
        "*://topamotor.com/*"
        "*://motorwithpassion.com/*"
        "*://gamesnewses.com/*"
        "*://technewsroll.com/*"
        "*://infonombre.com/*"
        "*://animationdraw.com/*"
        "*://recetasdegina.com/*"
        "*://mislyfashion.com/*"
        "*://techingro.com/*"
        "*://motoralm.com/*"
        "*://tocanimation.com/*"
        "*://letsmotorgo.com/*"
        "*://mangaplus.shueisha.co.jp/*"
        "*://*.japscan.ws/*"
        "*://*.animesvision.com.br/*"
        "*://*.animesvision.biz/*"
        "*://*.animes.vision/*"
        "*://www.hulu.com/*"
        "*://www.hidive.com/*"
        "*://*.primevideo.com/*"
        "*://mangakatana.com/manga/*"
        "*://*.manga4life.com/*"
        "*://bato.to/*"
        "*://mangapark.net/*"
        "*://animeshouse.net/episodio/*"
        "*://animeshouse.net/filme/*"
        "*://animexin.vip/*"
        "*://animexin.xyz/*"
        "*://animexinax.com/*"
        "*://monoschinos.com/*"
        "*://monoschinos2.com/*"
        "*://smotret-anime.com/catalog/*"
        "*://anime365.ru/catalog/*"
        "*://anime-365.ru/catalog/*"
        "*://animefire.net/*"
        "*://animefire.plus/*"
        "*://otakufr.co/*"
        "*://otakufr.cc/*"
        "*://mangatx.com/*"
        "*://manhuafast.com/*"
        "*://tranimeizle.net/*"
        "*://www.tranimeizle.net/*"
        "*://tranimeizle.co/*"
        "*://www.tranimeizle.co/*"
        "*://*.animestreamingfr.fr/*"
        "*://furyosociety.com/*"
        "*://www.animeid.tv/*"
        "*://myanimelist.net/anime/*/*/episode/*"
        "*://*.animeunity.it/anime/*"
        "*://*.animeunity.tv/anime/*"
        "*://*.animeunity.cc/anime/*"
        "*://*.animeunity.to/anime/*"
        "*://*.mangahere.cc/manga/*"
        "*://*.fanfox.net/manga/*"
        "*://*.mangafox.la/manga/*"
        "*://desu-online.pl/*"
        "*://wuxiaworld.site/novel/*"
        "*://lscomic.com/*"
        "*://en.leviatanscans.com/*"
        "*://reaperscans.com/comics/*"
        "*://lynxscans.com/*"
        "*://zeroscans.com/*"
        "*://reader.deathtollscans.net/*"
        "*://manhuaplus.com/manga*"
        "*://readm.org/manga/*"
        "*://www.readm.org/manga/*"
        "*://*.readm.today/manga/*"
        "*://tioanime.com/anime/*"
        "*://tioanime.com/ver/*"
        "*://yugenanime.tv/*"
        "*://yugenani.me/*"
        "*://yugen.to/*"
        "*://*.mangasee123.com/manga*"
        "*://*.mangasee123.com/read-online*"
        "*://*.okanime.com/animes/*"
        "*://*.okanime.com/movies/*"
        "*://*.okanime.tv/animes/*"
        "*://*.okanime.tv/movies/*"
        "*://bs.to/serie/*"
        "*://asura.gg/*"
        "*://*.asurascans.com/*"
        "*://*.asuracomics.com/*"
        "*://asuratoon.com/*"
        "*://an1me.nl/*"
        "*://an1me.to/*"
        "*://mangajar.com/manga/*"
        "*://mangajar.pro/manga/*"
        "*://*.otakustv.com/anime/*"
        "*://demo.komga.org/*"
        "*://animewho.com/*"
        "*://animesuge.io/anime/*"
        "*://animesuge.to/anime/*"
        "*://toonily.com/webtoon/*"
        "*://fumetsu.pl/anime/*"
        "*://frixysubs.pl/*"
        "*://guya.moe/*"
        "*://cubari.moe/*"
        "*://guya.cubari.moe/*"
        "*://mangahub.io/*"
        "*://comick.app/*"
        "*://comick.ink/*"
        "*://comick.cc/*"
        "*://comick.io/*"
        "*://www.bentomanga.com/*"
        "*://bentomanga.com/*"
        "*://mangasushi.net/manga*"
        "*://tritinia.com/manga*"
        "*://readmanhua.net/manga*"
        "*://flamecomics.com/*"
        "*://immortalupdates.com/manga*"
        "*://aniwatch.to/*"
        "*://aniwatch.nz/*"
        "*://aniwatch.se/*"
        "*://hianime.to/*"
        "*://kitsune.tv/*"
        "*://beta.kitsune.tv/*"
        "*://lhtranslation.net/manga*"
        "*://mangas-origines.fr/oeuvre*"
        "*://*.bluesolo.org/manga/*"
        "*://disasterscans.com/*"
        "*://dynasty-scans.com/*"
        "*://aniworld.to/*"
        "*://betteranime.net/anime/*"
        "*://*.manga.bilibili.com/*"
        "*://mangareader.to/*"
        "*://animeonsen.xyz/*"
        "*://www.animeonsen.xyz/*"
        "*://*.animetoast.cc/*"
        "*://luminousscans.com/*"
        "*://luminousscans.gg/*"
        "*://*.animeworld.tv/play/*"
        "*://*.animeworld.so/play/*"
        "*://mangabuddy.com/*"
        "*://void-scans.com/*"
        "*://vvww.toonanime.cc/*"
        "*://*.adkami.com/*"
        "*://kaguya.app/*"
        "*://hdrezka.ag/animation/*"
        "*://sovetromantica.com/anime/*"
        "*://ani.wtf/anime/*"
        "*://animationdigitalnetwork.fr/*"
        "*://animationdigitalnetwork.de/*"
        "*://aniyan.net/*"
        "*://docchi.pl/*"
        "*://franime.fr/*"
        "*://fmteam.fr/*"
        "*://www.animelon.com/*"
        "*://animelon.com/*"
        "*://anime-sama.fr/*"
        "*://mangafire.to/*"
        "*://projectsuki.com/*"
        "*://animebuff.ru/anime/*"
        "*://animeonegai.com/*"
        "*://www.animeonegai.com/*"
        "*://*.animeko.co/*"
        "*://animego.org/anime/*"
        "*://animeflix.gg/*"
        "*://animeflix.li/*"
        "*://*.luciferdonghua.in/*"
        "*://*.luciferdonghua.co.in/*"
        "*://neoxscans.com/*"
        "*://*.neoxscans.net/*"
        "*://*.anix.to/anime/*"
        "*://*.anix.ac/anime/*"
        "*://*.anix.vc/anime/*"
        "*://www.hinatasoul.com/anime*"
        "*://www.hinatasoul.com/videos/*"
        "*://ogladajanime.pl/*"
        "*://hachi.moe/*"
        "*://witanime.sbs/*"
        "*://witanime.pics/*"
        "*://suwayomi-webui-preview.github.io/*"
        "*://manhuaus.com/*"
        "*://*.taiyo.moe/*"
        "*://*.animesonline.in/*"
        "*://*.miruro.tv/*"
        "*://*.miruro.online/*"
        "*://latanime.org/*"
        "*://*.openload.co/*"
        "*://*.openload.pw/*"
        "*://*.streamango.com/*"
        "*://*.mp4upload.com/*"
        "*://*.mcloud.to/*"
        "*://*.mcloud.bz/*"
        "*://*.static.crunchyroll.com/*"
        "*://*.vidstreaming.io/*"
        "*://*.vidstreaming.link/*"
        "*://*.xstreamcdn.com/*"
        "*://*.gcloud.live/*"
        "*://*.oload.tv/*"
        "*://*.mail.ru/*"
        "*://*.myvi.ru/*"
        "*://*.myvi.tv/*"
        "*://*.sibnet.ru/*"
        "*://*.tune.pk/*"
        "*://*.tune.ke/*"
        "*://*.vimple.ru/*"
        "*://*.href.li/*"
        "*://*.vk.com/*"
        "*://*.cloudvideo.tv/*"
        "*://*.fembed.net/*"
        "*://*.fembed.com/*"
        "*://*.animeproxy.info/*"
        "*://*.feurl.com/*"
        "*://*.embedsito.com/v/*"
        "*://*.fcdn.stream/v/*"
        "*://*.fcdn.stream/e/*"
        "*://*.vaplayer.xyz/v/*"
        "*://*.vaplayer.xyz/e/*"
        "*://*.femax20.com/v/*"
        "*://*.femax20.com/e/*"
        "*://*.fplayer.info/*"
        "*://*.dutrag.com/*"
        "*://*.diasfem.com/*"
        "*://*.fembed-hd.com/*"
        "*://*.fembed9hd.com/*"
        "*://suzihaza.com/v/*"
        "*://vanfem.com/v/*"
        "*://*.youpload.co/*"
        "*://*.yourupload.com/*"
        "*://*.vidlox.me/*"
        "*://*.kwik.cx/*"
        "*://*.kwik.si/*"
        "*://*.mega.nz/*"
        "*://*.animeflv.net/*"
        "*://*.hqq.tv/*"
        "*://waaw.tv/*"
        "*://*.jkanime.net/*"
        "*://*.ok.ru/*"
        "*://*.novelplanet.me/*"
        "*://*.stream.proxer.me/*"
        "*://*.stream.proxer.net/*"
        "*://*.stream-service.proxer.me/*"
        "*://verystream.com/*"
        "*://*.animeultima.eu/e/*"
        "*://*.animeultima.eu/faststream/*"
        "*://*.animeultima.to/e/*"
        "*://*.animeultima.to/faststream/*"
        "*://*.vidoza.net/*"
        "*://gounlimited.to/*"
        "*://www.ani-stream.com/*"
        "*://animedaisuki.moe/embed/*"
        "*://www.dailymotion.com/embed/*"
        "*://vev.io/embed/*"
        "*://vev.red/embed/*"
        "*://jwpstream.com/jwps/yplayer.php*"
        "*://www.vaplayer.xyz/v/*"
        "*://vaplayer.me/*"
        "*://mp4.sh/embed/*"
        "*://embed.mystream.to/*"
        "*://*.bitchute.com/embed/*"
        "*://*.streamcherry.com/embed/*"
        "*://*.clipwatching.com/*"
        "*://*.flix555.com/*"
        "*://*.vshare.io/v/*"
        "*://ebd.cda.pl/*"
        "*://*.replay.watch/*"
        "*://*.playhydrax.com/*"
        "*://hydrax.net/*"
        "*://*.geoip.redirect-ads.com/*"
        "*://*.streamium.xyz/*"
        "*://kodik.info/*"
        "*://aniboom.one/*"
        "*://smotret-anime.com/translations/embed/*"
        "*://anime365.ru/translations/embed/*"
        "*://anime-365.ru/translations/embed/*"
        "*://*.pstream.net/e/*"
        "*://fusevideo.net/e/*"
        "*://fusevideo.io/e/*"
        "*://*.animefever.tv/embed/*"
        "*://*.haloani.ru/*"
        "*://*.moeclip.com/v/*"
        "*://*.moeclip.com/embed/*"
        "*://*.mixdrop.co/e/*"
        "*://*.mixdrop.to/e/*"
        "*://*.mdbekjwqa.pw/e/*"
        "*://*.mdfx9dc8n.net/e/*"
        "*://*.mdzsmutpcvykb.net/e/*"
        "*://*.mixdropjmk.pw/e/*"
        "*://*.mixdrop21.net/e/*"
        "*://*.mixdrop.si/e/*"
        "*://*.mixdrop.nu/e/*"
        "*://gdriveplayer.me/embed*"
        "*://sendvid.net/v/*"
        "*://sendvid.com/embed/*"
        "*://streamz.cc/*"
        "*://*.vidbm.com/embed-*"
        "*://*.vidbem.com/embed-*"
        "*://*.cloudhost.to/*/mediaplayer/*/_embed.php?*"
        "*://*.letsupload.co/*/mediaplayer/*/_embed.php?*"
        "*://streamtape.com/*"
        "*://streamtape.net/*"
        "*://streamtape.xyz/*"
        "*://streamtape.to/*"
        "*://strcloud.in/*"
        "*://strcloud.link/*"
        "*://streamta.pe/*"
        "*://strtape.tech/*"
        "*://strtapeadblock.club/*"
        "*://strtapeadblock.me/*"
        "*://streamta.site/*"
        "*://scloud.online/*"
        "*://strtpe.link/*"
        "*://stape.me/*"
        "*://stape.fun/*"
        "*://streamtapeadblock.art/*"
        "*://reproductor.monoschinos.com/*"
        "*://uptostream.com/iframe/*"
        "*://easyload.io/e/*"
        "*://*.googleusercontent.com/gadgets/*"
        "*://animedesu.pl/player/desu.php?v=*"
        "*://*.plyr.link/*"
        "*://v.vvid.cc/*"
        "*://*.okanime.com/cdn/*/embed/?*"
        "*://*.gogo-stream.com/streaming.php?*"
        "*://*.gogo-stream.com/load.php?*"
        "*://*.gogo-stream.com/loadserver.php?*"
        "*://*.gogo-stream.com/embedplus*"
        "*://*.gogo-play.net/streaming.php?*"
        "*://*.gogo-play.net/load.php?*"
        "*://*.gogo-play.net/loadserver.php?*"
        "*://*.gogo-play.net/embedplus*"
        "*://*.gogo-play.tv/streaming.php?*"
        "*://*.gogo-play.tv/load.php?*"
        "*://*.gogo-play.tv/loadserver.php?*"
        "*://*.gogo-play.tv/embedplus*"
        "*://*.streamani.net/streaming.php?*"
        "*://*.streamani.net/load.php?*"
        "*://*.streamani.net/loadserver.php?*"
        "*://*.streamani.net/embedplus*"
        "*://*.streamani.io/streaming.php?*"
        "*://*.streamani.io/load.php?*"
        "*://*.streamani.io/loadserver.php?*"
        "*://*.streamani.io/embedplus*"
        "*://*.goload.one/streaming.php?*"
        "*://*.goload.one/load.php?*"
        "*://*.goload.one/loadserver.php?*"
        "*://*.goload.one/embedplus*"
        "*://*.goload.pro/streaming.php?*"
        "*://*.goload.pro/load.php?*"
        "*://*.goload.pro/loadserver.php?*"
        "*://*.goload.pro/embedplus*"
        "*://*.goload.io/streaming.php?*"
        "*://*.goload.io/load.php?*"
        "*://*.goload.io/loadserver.php?*"
        "*://*.goload.io/embedplus*"
        "*://*.gogoplay1.com/streaming.php?*"
        "*://*.gogoplay1.com/load.php?*"
        "*://*.gogoplay1.com/loadserver.php?*"
        "*://*.gogoplay1.com/embedplus*"
        "*://*.gogoplay2.com/streaming.php?*"
        "*://*.gogoplay2.com/load.php?*"
        "*://*.gogoplay2.com/loadserver.php?*"
        "*://*.gogoplay2.com/embedplus*"
        "*://*.gogoplay4.com/streaming.php?*"
        "*://*.gogoplay4.com/load.php?*"
        "*://*.gogoplay4.com/loadserver.php?*"
        "*://*.gogoplay4.com/embedplus*"
        "*://*.gogoplay5.com/streaming.php?*"
        "*://*.gogoplay5.com/load.php?*"
        "*://*.gogoplay5.com/loadserver.php?*"
        "*://*.gogoplay5.com/embedplus*"
        "*://*.gogoplay.io/streaming.php?*"
        "*://*.gogoplay.io/load.php?*"
        "*://*.gogoplay.io/loadserver.php?*"
        "*://*.gogoplay.io/embedplus*"
        "*://*.gogohd.net/embedplus*"
        "*://*.gogohd.net/streaming.php?*"
        "*://*.gogohd.net/load.php?*"
        "*://*.gogohd.net/loadserver.php?*"
        "*://*.gogohd.pro/embedplus*"
        "*://*.gogohd.pro/streaming.php?*"
        "*://*.gogohd.pro/load.php?*"
        "*://*.gogohd.pro/loadserver.php?*"
        "*://*.gembedhd.com/embedplus*"
        "*://*.gembedhd.com/streaming.php?*"
        "*://*.gembedhd.com/load.php?*"
        "*://*.gembedhd.com/loadserver.php?*"
        "*://*.playgo1.cc/embedplus*"
        "*://*.playgo1.cc/streaming.php?*"
        "*://*.playgo1.cc/load.php?*"
        "*://*.playgo1.cc/loadserver.php?*"
        "*://*.anihdplay.com/embedplus*"
        "*://*.anihdplay.com/streaming.php?*"
        "*://*.anihdplay.com/load.php?*"
        "*://*.anihdplay.com/loadserver.php?*"
        "*://*.playtaku.net/embedplus*"
        "*://*.playtaku.net/streaming.php?*"
        "*://*.playtaku.net/load.php?*"
        "*://*.playtaku.net/loadserver.php?*"
        "*://*.playtaku.online/embedplus*"
        "*://*.playtaku.online/streaming.php?*"
        "*://*.playtaku.online/load.php?*"
        "*://*.playtaku.online/loadserver.php?*"
        "*://*.gotaku1.com/embedplus*"
        "*://*.gotaku1.com/streaming.php?*"
        "*://*.gotaku1.com/load.php?*"
        "*://*.gotaku1.com/loadserver.php?*"
        "*://*.goone.pro/embedplus*"
        "*://*.goone.pro/streaming.php?*"
        "*://*.goone.pro/load.php?*"
        "*://*.goone.pro/loadserver.php?*"
        "*://*.embtaku.pro/embedplus*"
        "*://*.embtaku.pro/streaming.php?*"
        "*://*.embtaku.pro/load.php?*"
        "*://*.embtaku.pro/loadserver.php?*"
        "*://*.embtaku.com/embedplus*"
        "*://*.embtaku.com/streaming.php?*"
        "*://*.embtaku.com/load.php?*"
        "*://*.embtaku.com/loadserver.php?*"
        "*://vivo.sx/embed/*"
        "*://play.api-web.site/*"
        "*://vidstream.pro/embed/*"
        "*://vidstream.pro/e/*"
        "*://vidstreamz.online/embed/*"
        "*://vidstreamz.online/e/*"
        "*://vizcloud.ru/embed/*"
        "*://vizcloud.ru/e/*"
        "*://vizcloud2.ru/embed/*"
        "*://vizcloud2.ru/e/*"
        "*://vizcloud.online/embed/*"
        "*://vizcloud.online/e/*"
        "*://vizstream.ru/embed/*"
        "*://vizstream.ru/e/*"
        "*://vizcloud.xyz/embed/*"
        "*://vizcloud.xyz/e/*"
        "*://vizcloud.cloud/embed/*"
        "*://vizcloud.cloud/e/*"
        "*://vizcloud.co/embed/*"
        "*://vizcloud.co/e/*"
        "*://vidplay.site/e/*"
        "*://vidplay.lol/e/*"
        "*://vidplay.online/e/*"
        "*://a9bfed0818.nl/e/*"
        "*://vid142.site/e/*"
        "*://streamsb.net/*"
        "*://streamsb.com/*"
        "*://sbembed.com/*"
        "*://sbembed1.com/*"
        "*://sbvideo.net/*"
        "*://sbplay.org/*"
        "*://sbplay.one/*"
        "*://sbplay1.com/*"
        "*://sbplay2.com/*"
        "*://embedsb.com/*"
        "*://watchsb.com/*"
        "*://sbplay2.xyz/*"
        "*://sbfull.com/e/*"
        "*://ssbstream.net/*"
        "*://streamsss.net/*"
        "*://sbanh.com/e/*"
        "*://sblongvu.com/e/*"
        "*://sbchill.com/e/*"
        "*://sbone.pro/e/*"
        "*://sbani.pro/e/*"
        "*://dood.to/*"
        "*://dood.watch/*"
        "*://doodstream.com/*"
        "*://dood.la/*"
        "*://*.dood.video/*"
        "*://dood.ws/e/*"
        "*://dood.sh/e/*"
        "*://dood.so/e/*"
        "*://dood.pm/e/*"
        "*://dood.wf/e/*"
        "*://dood.re/e/*"
        "*://dooood.com/e/*"
        "*://youtube.googleapis.com/embed/*drive.google.com*"
        "*://hdvid.tv/*"
        "*://vidfast.co/*"
        "*://supervideo.tv/*"
        "*://jetload.net/*"
        "*://saruch.co/*"
        "*://vidmoly.me/*"
        "*://vidmoly.to/*"
        "*://upstream.to/*"
        "*://abcvideo.cc/*"
        "*://aparat.cam/*"
        "*://www.aparat.com/video/video/embed/*"
        "*://vudeo.net/*"
        "*://voe.sx/e/*"
        "*://voe-unblock.com/e/*"
        "*://voe-unblock.net/e/*"
        "*://voeunblock.com/e/*"
        "*://voeunblock1.com/e/*"
        "*://voeunblock2.com/e/*"
        "*://voeunblock3.com/e/*"
        "*://voeunbl0ck.com/e/*"
        "*://voeunblck.com/e/*"
        "*://voeunblk.com/e/*"
        "*://voe-un-block.com/e/*"
        "*://voeun-block.net/e/*"
        "*://un-block-voe.net/e/*"
        "*://v-o-e-unblock.com/e/*"
        "*://audaciousdefaulthouse.com/e/*"
        "*://launchreliantcleaverriver.com/e/*"
        "*://reputationsheriffkennethsand.com/e/*"
        "*://fittingcentermondaysunday.com/e/*"
        "*://voe.bar/e/*"
        "*://housecardsummerbutton.com/e/*"
        "*://fraudclatterflyingcar.com/e/*"
        "*://bigclatterhomesguideservice.com/e/*"
        "*://uptodatefinishconferenceroom.com/e/*"
        "*://realfinanceblogcenter.com/e/*"
        "*://tinycat-voe-fashion.com/e/*"
        "*://20demidistance9elongations.com/e/*"
        "*://telyn610zoanthropy.com/e/*"
        "*://toxitabellaeatrebates306.com/e/*"
        "*://greaseball6eventual20.com/e/*"
        "*://745mingiestblissfully.com/e/*"
        "*://19turanosephantasia.com/e/*"
        "*://30sensualizeexpression.com/e/*"
        "*://321naturelikefurfuroid.com/e/*"
        "*://449unceremoniousnasoseptal.com/e/*"
        "*://guidon40hyporadius9.com/e/*"
        "*://cyamidpulverulence530.com/e/*"
        "*://boonlessbestselling244.com/e/*"
        "*://antecoxalbobbing1010.com/e/*"
        "*://matriculant401merited.com/e/*"
        "*://scatch176duplicities.com/e/*"
        "*://35volitantplimsoles5.com/e/*"
        "*://tummulerviolableness.com/e/*"
        "*://tubelessceliolymph.com/e/*"
        "*://availedsmallest.com/e/*"
        "*://counterclockwisejacky.com/e/*"
        "*://monorhinouscassaba.com/e/*"
        "*://urochsunloath.com/e/*"
        "*://simpulumlamerop.com/e/*"
        "*://sizyreelingly.com/e/*"
        "*://rationalityaloelike.com/e/*"
        "*://wolfdyslectic.com/e/*"
        "*://metagnathtuggers.com/e/*"
        "*://gamoneinterrupted.com/e/*"
        "*://chromotypic.com/e/*"
        "*://crownmakermacaronicism.com/e/*"
        "*://generatesnitrosate.com/e/*"
        "*://yodelswartlike.com/e/*"
        "*://figeterpiazine.com/e/*"
        "*://cigarlessarefy.com/e/*"
        "*://valeronevijao.com/e/*"
        "*://strawberriesporail.com/e/*"
        "*://timberwoodanotia.com/e/*"
        "*://phenomenalityuniform.com/e/*"
        "*://prefulfilloverdoor.com/e/*"
        "*://nonesnanking.com/e/*"
        "*://kathleenmemberhistory.com/e/*"
        "*://denisegrowthwide.com/e/*"
        "*://troyyourlead.com/e/*"
        "*://stevenimaginelittle.com/e/*"
        "*://edwardarriveoften.com/e/*"
        "*://lukecomparetwo.com/e/*"
        "*://kennethofficialitem.com/e/*"
        "*://bradleyviewdoctor.com/e/*"
        "*://jamiesamewalk.com/e/*"
        "*://seanshowcould.com/e/*"
        "*://johntryopen.com/e/*"
        "*://morganoperationface.com/e/*"
        "*://markstyleall.com/e/*"
        "*://jayservicestuff.com/e/*"
        "*://vincentincludesuccessful.com/e/*"
        "*://brookethoughi.com/e/*"
        "*://jamesstartstudent.com/e/*"
        "*://ryanagoinvolve.com/e/*"
        "*://jasonresponsemeasure.com/e/*"
        "*://graceaddresscommunity.com/e/*"
        "*://shannonpersonalcost.com/e/*"
        "*://cindyeyefinal.com/e/*"
        "*://michaelapplysome.com/e/*"
        "*://sethniceletter.com/e/*"
        "*://vidoo.tv/*"
        "*://nxload.com/*"
        "*://videobin.co/*"
        "*://uqload.com/*"
        "*://evoload.io/*"
        "*://yugenani.me/e/*"
        "*://yugen.to/e/*"
        "*://yugenanime.ro/e/*"
        "*://yugenanime.tv/e/*"
        "*://kaa-play.me/*"
        "*://kaavid.com/*"
        "*://vidnethub.net/*"
        "*://vidco.pro/*"
        "*://*.animeshouse.net/gcloud/*"
        "*://*.animeshouse.net/playerBlue/*"
        "*://*.animeshouse.net/mp4/*"
        "*://*.animeshouse.net/ah-clp-new/*"
        "*://animato.me/embed/*"
        "*://kimanime.ru/AnimeIframe/*"
        "*://vidcloud.spb.ru/*"
        "*://*.streamhd.cc/*"
        "*://*.rapid-cloud.ru/*"
        "*://*.rapid-cloud.co/*"
        "*://videovard.sx/*"
        "*://videovard.to/*"
        "*://streamlare.com/e/*"
        "*://betteranime.net/player*"
        "*://streamzz.to/*"
        "*://protonvideo.to/iframe/*"
        "*://ninjastream.to/watch/*"
        "*://harajuku.pl/*"
        "*://vupload.com/*"
        "*://*.turkanime.net/player/*"
        "*://*.turkanime.co/player/*"
        "*://*.turkanime.co/embed/*"
        "*://play.cozyplayer.com/*"
        "*://odnoklassniki.ru/*"
        "*://myalucard.xyz/*"
        "*://uploads.mobi/*"
        "*://iframe.mediadelivery.net/embed/*"
        "*://*.yfvf.com/*"
        "*://waaw.to/*"
        "*://suzihaza.com/*"
        "*://*.solidfiles.com/*"
        "*://www.animeworld.tv/api/episode/serverPlayerAnimeWorld?id=*"
        "*://www.animeworld.so/api/episode/serverPlayerAnimeWorld?id=*"
        "*://filemoon.sx/e/*"
        "*://kerapoxy.cc/e/*"
        "*://vpcxz19p.xyz/e/*"
        "*://filemoon.top/e/*"
        "*://fmoonembed.pro/e/*"
        "*://rgeyyddl.skin/e/*"
        "*://designparty.sx/e/*"
        "*://mb.toonanime.xyz/dist/*"
        "*://aniyan.net/jwplayer/*"
        "*://*.googlevideo.com/videoplayback?*"
        "*://*.streamhide.to/e/*"
        "*://api.animeflix.live/*"
        "*://api.animeflix.dev/*"
        "*://*.animeflix.ci/player?*"
        "*://megacloud.tv/*"
        "*://vixcloud.cc/*"
        "*://vixcloud.co/*"
        "*://yonaplay.org/*"
        "*://*.4shared.com/*"
        "*://*.videa.hu/*"
        "*://*.soraplay.xyz/*"
        "*://streamwish.to/e/*"
        "*://sfastwish.com/e/*"
        "*://awish.pro/e/*"
        "*://alions.pro/v/*"
        "*://*.anitaku.pe/*"
        "*://*.asuracomic.net/*"
        "*://hivetoon.com/*"
        "*://animationdigitalnetwork.com/*"
        "*://*.mangaread.org/manga/*"
        "*://bakashi.tv/*"
        "*://*.mixdrop.sx/e/*"
        "*://*.mixdrop.ms/e/*"
        "*://*.mixdrop.ps/e/*"
        "*://*.gogo-stream.com/*"
        "*://*.gogo-play.net/*"
        "*://*.gogo-play.tv/*"
        "*://*.streamani.net/*"
        "*://*.streamani.io/*"
        "*://*.goload.one/*"
        "*://*.goload.pro/*"
        "*://*.goload.io/*"
        "*://*.gogoplay1.com/*"
        "*://*.gogoplay2.com/*"
        "*://*.gogoplay4.com/*"
        "*://*.gogoplay5.com/*"
        "*://*.gogoplay.io/*"
        "*://*.gogohd.net/*"
        "*://*.gogohd.pro/*"
        "*://*.gembedhd.com/*"
        "*://*.playgo1.cc/*"
        "*://*.anihdplay.com/*"
        "*://*.playtaku.net/*"
        "*://*.playtaku.online/*"
        "*://*.gotaku1.com/*"
        "*://*.goone.pro/*"
        "*://*.embtaku.pro/*"
        "*://*.embtaku.com/*"
        "*://*.s3taku.com/*"
        "*://vid1a52.site/e/*"
        "*://vid2a41.site/e/*"
        "*://brucevotewithin.com/e/*"
        "*://rebeccaneverbase.com/e/*"
        "*://loriwithinfamily.com/e/*"
        "*://c4qhk0je.xyz/e/*"
        "*://1azayf9w.xyz/e/*"
        "*://81u6xl9d.xyz/e/*"
        "*://megaf.cc/e/*"
        "*://doflix.net/*"
        "*://kitsu.app/*"
        "*://smotret-anime.net/catalog/*"
        "*://reaperscans.com/*"
        "*://luminous-scans.com/*"
        "*://*.anix.to/*"
        "*://*.anix.ac/*"
        "*://*.anix.vc/*"
        "*://templescan.net/*"
        "*://www.lycoris.cafe/*"
        "*://smotret-anime.net/translations/embed/*"
        "*://*.kaa.mx/*"
        "*://*.tranimeizle.top/*"
        "*://animenosub.to/*"
        "*://ranobelib.me/*"
        "*://rawkuma.com/*"
        "*://animekai.to/*"
        "*://watch.hikaritv.xyz/*"
        "*://hikari.gg/*"
        "*://maxfinishseveral.com/e/*"
        "*://krussdomi.com/*"
        "*://filemoon.sx/lol/*"
        "*://kerapoxy.cc/lol/*"
        "*://vpcxz19p.xyz/lol/*"
        "*://filemoon.top/lol/*"
        "*://fmoonembed.pro/lol/*"
        "*://rgeyyddl.skin/lol/*"
        "*://designparty.sx/lol/*"
        "*://c4qhk0je.xyz/lol/*"
        "*://1azayf9w.xyz/lol/*"
        "*://81u6xl9d.xyz/lol/*"
        "*://gorro-chfzoaas.fun/e/*"
        "*://gorro-chfzoaas.fun/lol/*"
        "*://animenosub.upn.one/#*"
        "*://*.bunniescdn.online/*"
        "*://megaup.cc/e/*"
      ];
    };
    "multi-account-containers" = {
      permissions = [
        "<all_urls>"
        "activeTab"
        "cookies"
        "contextMenus"
        "contextualIdentities"
        "history"
        "idle"
        "management"
        "storage"
        "unlimitedStorage"
        "tabs"
        "webRequestBlocking"
        "webRequest"
      ];
    };
    "ublock-origin" = {
      permissions = [
        "dns"
        "menus"
        "privacy"
        "storage"
        "tabs"
        "alarms"
        "unlimitedStorage"
        "webNavigation"
        "webRequest"
        "webRequestBlocking"
        "<all_urls>"
        "http://*/*"
        "https://*/*"
        "file://*/*"
        "https://easylist.to/*"
        "https://*.fanboy.co.nz/*"
        "https://filterlists.com/*"
        "https://forums.lanik.us/*"
        "https://github.com/*"
        "https://*.github.io/*"
        "https://*.letsblock.it/*"
        "https://github.com/uBlockOrigin/*"
        "https://ublockorigin.github.io/*"
        "https://*.reddit.com/r/uBlockOrigin/*"
      ];
    };
    "bitwarden" = {
      permissions = [
        "tabs"
        "alarms"
        "contextMenus"
        "storage"
        "unlimitedStorage"
        "clipboardRead"
        "clipboardWrite"
        "idle"
        "http://*/*"
        "https://*/*"
        "webRequest"
        "webRequestBlocking"
        "file:///*"
        "https://lastpass.com/export.php"
        "<all_urls>"
        "*://*/*"
        "webNavigation"
      ];
    };
    "darkreader" = {
      permissions = ["alarms" "contextMenus" "storage" "tabs" "theme" "<all_urls>"];
    };
    "tridactyl" = {
      permissions = [
        "activeTab"
        "bookmarks"
        "browsingData"
        "contextMenus"
        "contextualIdentities"
        "cookies"
        "clipboardWrite"
        "clipboardRead"
        "downloads"
        "find"
        "history"
        "search"
        "sessions"
        "storage"
        "tabHide"
        "tabs"
        "topSites"
        "management"
        "nativeMessaging"
        "webNavigation"
        "webRequest"
        "webRequestBlocking"
        "proxy"
        "<all_urls>"
      ];
    };
  };
in {
  assertions =
    lib.mapAttrsToList (k: v: let
      unaccepted =
        lib.subtractLists v.permissions
        pkgs.nur.repos.rycee.firefox-addons.${k}.meta.mozPermissions;
    in {
      assertion = unaccepted == [];
      message = "Extension ${k} has unaccepted permissions: ${
        builtins.toJSON unaccepted
      }";
    })
    extensions;
}
