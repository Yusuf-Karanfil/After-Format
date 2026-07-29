# 
  AFTER FORMAT — FORMAT SONRASI OTOMATIK KURULUM ARACI
================================================================



  Bu araç, yeni formatlanmış bir Windows kurulumunu;
  - Gereksiz uygulamalardan arındırır
  - Gerekli programları otomatik kurar
  - Kullanıcının elle yapacağı onlarca ufak ayarı toptan yapar
  - Diski temizler ve performansı optimize eder

  Amaç: Kahveni al, tıkla, bekle. Elle uğraşmak yok.


----------------------------------------------------------------
  KULLANIM SIRASI — ÇOK ÖNEMLİ, SIRAYLA YAP
----------------------------------------------------------------

  [1] Windows'u kur ve ilk açılışı tamamla (Microsoft hesabı,
      dil, saat dilimi vs.).

  [2] Bu klasörü masaüstüne at.

  [3] Internet baglantisinin calistigindan emin ol.

  [4] >>> 1_surucuden_once.bat <<< dosyasina çift tikla
      - Yonetici izni ister, "Evet" de
      - Chrome kurulur ve varsayilan tarayici yapilir
      - Windows Update calisir (10-30 dk surebilir)
      - Bitince "BITTI" yazisini gor, pencereyi kapat

  [5] >>> BILGISAYARI YENIDEN BASLAT <<<
      - Bekleyen guncellemelerin tam oturmasi icin sart

  [6] Suruculeri kur:
      - Anakart surucusu (uretici sitesinden indir)
      - Ekran karti (NVIDIA / AMD / Intel)
      - Ses karti
      - Ag karti (wifi, bluetooth)
      - Chipset / LAN / diger
      Her surucu kurulumundan sonra RES AT.
      Butun suruculer oturduktan sonra devam et.

  [7] >>> 2_surucuden_sonra.bat <<< dosyasina çift tikla
      - Yonetici izni ister, "Evet" de
      - Sistem geri yukleme noktasi olusturulur
      - VS Code, PowerShell 7, Python, VLC, AnyDesk, WinRAR,
        FileZilla, Windows Terminal kurulur
      - Bloatware (Xbox, Your Phone, Bing News, Teams, vs.) silinir
      - OneDrive tamamen kaldirilir
      - Edge reklamlari / sidebar / shopping daraltilir
      - Gorev cubugu, Explorer, gizlilik ayarlari yapilir
      - Lock screen reklamlari kapatilir
      - Windows Terminal varsayilan terminal yapilir
      - Bitince "BITTI" yazisini gor, pencereyi kapat

  [8] >>> 3_temizlik.bat <<< dosyasina çift tikla
      - Yonetici izni ister, "Evet" de
      - TEMP klasorleri, Windows Update cache temizlenir
      - DISM /ResetBase calisir (5-15 dk surebilir, DOKUNMA)
      - Thumbnail/icon cache, WER loglari, dump dosyalari silinir
      - Geri donusum bosaltilir
      - Hibernate dosyasi kapatilir (RAM kadar alan acilir)
      - NTFS optimizasyonlari yapilir
      - DiagTrack ve Xbox servisleri kapatilir
      - SSD icin TRIM calistirilir
      - SMART disk saglik kontrolu yapilir
      - Bitince "BITTI" yazisini gor, kazanilan disk alanini gor

  [9] >>> BILGISAYARI BIR KEZ DAHA YENIDEN BASLAT <<<
      - Registry ve fsutil degisikliklerinin tam oturmasi icin


----------------------------------------------------------------
  NE OLDU — GENEL OLARAK YAPILAN ISLEMLER
----------------------------------------------------------------

  > UYGULAMA YONETIMI
    - Windows'ta yuklu gelen gereksiz uygulamalar (Xbox, Your Phone,
      OneDrive, Teams, Bing News/Weather, Clipchamp, Solitaire,
      People, Feedback Hub, Get Help, Get Started, Zune vs.)
      tamamen kaldirildi.
    - Yerlerine; Chrome, VS Code, PowerShell 7, Windows Terminal,
      Python, FileZilla, VLC, AnyDesk, WinRAR kuruldu.

  > KULLANICI AYARLARI (elle 1-2 saat surecek seyler)
    - Dosya uzantilari ve gizli dosyalar gorunur yapildi.
    - Explorer "This PC" ile aciliyor (Quick Access yerine).
    - Klasik sag tik menusu geri getirildi (Win11).
    - Gorev cubugu: Widget, Task View, Search kutusu, Chat gizlendi.
    - Pano gecmisi (Win+V) acildi.
    - Masaustunde This PC, Network, Recycle Bin ikonlari gorunur.
    - Menu acilma gecikmesi sifirlandi.
    - Explorer Home ve Gallery navigation pane'den gizlendi.
    - Windows Terminal varsayilan terminal yapildi.
    - Developer Mode, Long Path Support acildi.
    - PowerShell ExecutionPolicy: RemoteSigned.

  > GIZLILIK VE REKLAM TEMIZLIGI
    - Reklam ID, activity history, feedback kapatildi.
    - Telemetri minimum seviyeye cekildi.
    - Inking, typing, background apps kapatildi.
    - Start menude web aramasi ve Cortana onerileri kapatildi.
    - Lock screen reklamlari, "fun facts", Spotlight kapatildi.
    - "Get even more out of Windows" ekrani kapatildi.
    - Settings sayfasindaki onerilen icerik reklamlari kapatildi.
    - Edge: sidebar, shopping assistant, Copilot paneli,
      startup boost, background mode, telemetri kapatildi.
      (Edge'in kendi guvenlik guncellemesi ACIK birakildi.)

  > GUVENLIK
    - NetBIOS over TCP/IP kapatildi (eski zafiyet).
    - Ag kesfi Public ag icin kapatildi.
    - Sistem geri yukleme noktasi olusturuldu (bir seyler ters
      giderse geri alabilirsin).

  > DISK VE PERFORMANS
    - TEMP, Windows Update cache, WER loglari, CBS loglari,
      DISM loglari, memory dumps, thumbnail/icon cache silindi.
    - WinSxS (Windows komponent deposu) /ResetBase ile tamamen
      sikistirildi (update rollback imkani gider, alan kazanilir).
    - Hibernate dosyasi (hiberfil.sys) kapatildi, RAM kadar
      disk alani geri kazanildi.
    - NTFS: last-access time ve 8.3 kisa dosya adi kapatildi
      (I/O hizi artar, modern sistem icin guvenli).
    - Storage Sense: geri donusum kutusu 30 gunde bir otomatik
      bosalir (guvenli mod, kullanici dosyalarina dokunmaz).
    - DiagTrack (telemetri servisi) ve Xbox servisleri kapatildi.
    - SSD ise TRIM aktif edildi ve calistirildi.
    - SMART: tum disklerin saglik durumu raporlandi.


----------------------------------------------------------------
  GEREKSINIMLER
----------------------------------------------------------------

  - Windows 10 / 11 (23H2 onerilir)
  - Yonetici yetkisi (scriptler otomatik ister)
  - Internet baglantisi
  - winget (Windows 11'de hazir, Win 10'da Microsoft Store >
    App Installer guncel olmali)

================================================================
