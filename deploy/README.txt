DEPLOY MANIFESTS
================

What goes onto each machine's live ACP folders.  A machine's deploy is manifest-common.txt plus
manifest-<observatory>.txt, where the observatory comes from the hostname the way Wise.Util.wsc
maps it:

    dome-pc -> wise40       c28-pc -> c28       h80-pc -> h80       wo-neo -> c18 (no manifest yet)

These files are only data.  The deploy script that reads them is not written yet; until it is,
they are the written-down answer to "which file goes where, on which machine".


FORMAT
------

One entry per line, fields separated by whitespace.  Blank lines and lines starting with # are
ignored.  Anything after a field that needs a space is written in double quotes.

    file      <source> <dest>        copy one file.  A dest ending in \ is a folder.
    tree      <source> <dest>        copy a folder, recursively, into the dest folder.
    external  <source> <dest>        like file, but the source is in another repository, written
                                     as <repo>:<path>.
    register  <dest>                 after copying, register the .wsc at <dest> with the 32-bit
                                     regsvr32 (C:\Windows\SysWOW64), elevated.  Entries run in
                                     the order written, common first.

Sources are relative to the root of this repository, with forward slashes.  Dests are Windows paths
starting with a root token:

    {acp}        C:\Program Files (x86)\ACP Obs Control
    {scheduler}  C:\Users\Public\Documents\ACP Config\Scheduler


NOT COVERED
-----------

  - WiseWeatherSetup (the .NET weather setup, registered with RegAsm).  It is built output, not
    a file in this repository.
  - qhy550p_com.py --register on h80 (see Scripts\Wise\H80.obs\README.md).
  - WiseSettings\*.json.  Nothing reads them yet (Wise.Util.get_settings_file is unused), so it
    is not decided where they go.
  - Removing files that should no longer be there, such as the live FS2_Sync.vbs.  A manifest
    only says what to put down.
