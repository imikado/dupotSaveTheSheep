rm -rf export/Linux/bundle
rm -f export/Linux/bundle.tar.gz
mkdir export/Linux/bundle
cp export/Linux/dupotSaveTheSheep.pck export/Linux/bundle
cp -r export/Linux/flatpak/icons export/Linux/bundle/
cp export/Linux/flatpak/org.dupot.savethesheep.appdata.xml export/Linux/bundle/
cp export/Linux/flatpak/org.dupot.savethesheep.desktop export/Linux/bundle/
tar -cvzf export/Linux/bundle.tar.gz -C export/Linux/bundle .

