#!/usr/bin/env bash
# Download the third-party tools used by the project into tools/.
# Already-present tools are skipped, so the script can be re-run safely.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS="$ROOT/tools"
mkdir -p "$TOOLS"
cd "$TOOLS"

FUSEKI_VERSION=5.3.0
JETTY_VERSION=9.4.57.v20241219
RMLMAPPER_VERSION=7.3.3
RMLMAPPER_JAR=rmlmapper-7.3.3-r374-all.jar
WIDOCO_VERSION=1.4.25
WIDOCO_JAR=widoco-1.4.25-jar-with-dependencies_JDK-11.jar
ROBOT_VERSION=1.9.7
XAMPP_INSTALLER=xampp-linux-x64-8.0.30-0-installer.run

fetch() { # fetch <url> <output file>
    echo "  -> downloading $2"
    curl -fL --progress-bar -o "$2.part" "$1"
    mv "$2.part" "$2"
}

echo "Apache Jena Fuseki $FUSEKI_VERSION"
if [ ! -f "apache-jena-fuseki-$FUSEKI_VERSION/fuseki-server.jar" ]; then
    fetch "https://archive.apache.org/dist/jena/binaries/apache-jena-fuseki-$FUSEKI_VERSION.tar.gz" fuseki.tar.gz
    tar xzf fuseki.tar.gz && rm fuseki.tar.gz
fi

echo "Jetty $JETTY_VERSION (hosts the Pubby webapp in pubby/)"
if [ ! -f "jetty-distribution-$JETTY_VERSION/start.jar" ]; then
    fetch "https://repo1.maven.org/maven2/org/eclipse/jetty/jetty-distribution/$JETTY_VERSION/jetty-distribution-$JETTY_VERSION.tar.gz" jetty.tar.gz
    tar xzf jetty.tar.gz && rm jetty.tar.gz
fi

echo "RMLMapper $RMLMAPPER_VERSION"
[ -f "$RMLMAPPER_JAR" ] || fetch "https://github.com/RMLio/rmlmapper-java/releases/download/v$RMLMAPPER_VERSION/$RMLMAPPER_JAR" "$RMLMAPPER_JAR"

echo "Widoco $WIDOCO_VERSION"
[ -f "$WIDOCO_JAR" ] || fetch "https://github.com/dgarijo/Widoco/releases/download/v$WIDOCO_VERSION/$WIDOCO_JAR" "$WIDOCO_JAR"

echo "ROBOT $ROBOT_VERSION"
[ -f robot.jar ] || fetch "https://github.com/ontodev/robot/releases/download/v$ROBOT_VERSION/robot.jar" robot.jar
if [ ! -f robot ]; then
    fetch "https://raw.githubusercontent.com/ontodev/robot/v$ROBOT_VERSION/bin/robot" robot
    chmod +x robot
fi

if [ "$(uname -s)" = "Linux" ]; then
    echo "XAMPP 8.0.30 installer"
    if [ ! -f "$XAMPP_INSTALLER" ]; then
        fetch "https://sourceforge.net/projects/xampp/files/XAMPP%20Linux/8.0.30/$XAMPP_INSTALLER/download" "$XAMPP_INSTALLER"
        chmod +x "$XAMPP_INSTALLER"
    fi
else
    echo "XAMPP: skipped (Linux only)"
fi

if [ ! -x virtuoso/bin/virtuoso-start.sh ]; then
    cat <<EOF

[!] Virtuoso is not installed in tools/virtuoso/.
    It cannot be downloaded automatically. Download the Virtuoso 8.3 Linux
    binary package from https://virtuoso.openlinksw.com/download/, extract it
    into tools/virtuoso/ and run its ./install.sh from that folder.
    Only the faceted browser (faceted.ceribouchetiflor.be) depends on it.
EOF
fi

echo
echo "Done. Tools are in $TOOLS"
