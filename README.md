MyBACKUP Remote Backup Tool
=============================

Das Kommandozeilen-Tool `mybackup` sichert Dateien und Verzeichnisse auf entfernten Datensicherungssystemen basierend auf dem Tool `rsync`.

Ein typisches entferntes System kann z.B. ein FreeNAS-Server mit aktiviertem rsync- und ssh-Deamon (Service)  sein.

Aufruf
-------

```
Usage: mybackup [init|get|help|log|push|remote|status|test]

Using: /usr/bin/rsync
```

Neues Datensicherungsprojekt anlegen
-------------------------------------

```
cd $PROJECT-ROOT
mybackup init --save
```

Die Option `--save` bewirkt, das im aktuellen Verzeichnis ein `.mybackup` Projektordner angelegt wird. Anschließend müssen die JOB- und SERVER-Definitionsdateien noch angepasst werden.

Datensicherung
---------------

```
cd $PROJECT-ROOT
mybackup status
```

Das Kommando `status` startet einen `rsync`-DryRun.

```
cd $PROJECT-ROOT
mybackup push [--delete]
```
