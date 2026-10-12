# Third-party tools live in tools/ (see scripts/setup.sh)
TOOLS         := tools
FUSEKI_JAR    := $(TOOLS)/apache-jena-fuseki-5.3.0/fuseki-server.jar
JETTY_HOME    := $(TOOLS)/jetty-distribution-9.4.57.v20241219
VIRTUOSO_HOME := $(TOOLS)/virtuoso
RMLMAPPER     := $(TOOLS)/rmlmapper-7.3.3-r374-all.jar
WIDOCO        := $(TOOLS)/widoco-1.4.25-jar-with-dependencies_JDK-11.jar
XAMPP         := $(TOOLS)/xampp-linux-x64-8.0.30-0-installer.run
LAMPP         := /opt/lampp
PYTHON        ?= python3
LOGS          := logs

.PHONY: help setup install db db-stop kg validate docs run stop

help:
	@echo "make setup     Download third-party tools into $(TOOLS)/"
	@echo "make install   Install XAMPP into $(LAMPP) (needs root)"
	@echo "make db        Start the MySQL source databases + phpMyAdmin (Docker)"
	@echo "make db-stop   Stop the Docker databases"
	@echo "make kg        Generate data/output.ttl from MySQL with RMLMapper"
	@echo "make validate  Validate data/output.ttl against the SHACL shapes"
	@echo "make docs      Regenerate the Widoco ontology documentation"
	@echo "make run       Start Apache, Fuseki, Pubby, YASGUI and Virtuoso"
	@echo "make stop      Stop everything started by 'make run'"

setup:
	./scripts/setup.sh

install: setup
	sudo $(XAMPP)

db:
	docker compose up -d

db-stop:
	docker compose down

kg:
	java -jar $(RMLMAPPER) -m mapping/mapping.ttl -o data/output.ttl -s turtle

validate:
	$(PYTHON) validation/validate.py

docs:
	java -jar $(WIDOCO) -ontFile ontology/krr_QL.ttl -outFolder docs/ontology \
		-lang en-fr -webVowl -htaccess -getOntologyMetadata -rewriteAll

run:
	mkdir -p $(LOGS)
	sudo cp -r docs/ontology $(LAMPP)/htdocs/
	sudo cp config/apache/httpd.conf $(LAMPP)/apache2/conf/httpd.conf
	sudo $(LAMPP)/lampp restart
	FUSEKI_BASE=fuseki nohup java -XX:+UseG1GC -XX:MaxGCPauseMillis=100 -jar $(FUSEKI_JAR) > $(LOGS)/fuseki.log 2>&1 &
	cd pubby && nohup java -jar ../$(JETTY_HOME)/start.jar > ../$(LOGS)/pubby.log 2>&1 &
	cd yasgui && nohup $(PYTHON) -m http.server 6942 > ../$(LOGS)/yasgui.log 2>&1 &
	sudo $(VIRTUOSO_HOME)/bin/virtuoso-start.sh

stop:
	-sudo $(LAMPP)/lampp stop
	-pkill -f fuseki-server.jar
	-pkill -f "$(notdir $(JETTY_HOME))/start.jar"
	-pkill -f "http.server 6942"
	-sudo $(VIRTUOSO_HOME)/bin/virtuoso-stop.sh
