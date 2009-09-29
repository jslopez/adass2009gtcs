SHELL=/bin/bash

# Which pdf file should I construct?
NOMBRE=$(shell grep -H ^[^%].*\\documentclass *.tex | cut -d: -f1 | cut -d. -f1)

DEPENDENCIES=$(NOMBRE).tex

ifeq ($(strip $(wildcard $(NOMBRE).bib) ),)
HAVE_BIB=no
else
HAVE_BIB=yes
endif

ifeq '$(HAVE_BIB)' 'yes'
DEPENDENCIES+= $(strip $(wildcard $(NOMBRE).bib) )
endif

IMGDIR = img

# Which images should I construct?
ALL_IMAGES  = $(wildcard $(IMGDIR)/*.dia)
ALL_IMAGES += $(wildcard $(IMGDIR)/*.svg)
ALL_IMAGES += $(wildcard $(IMGDIR)/*.jpg)
ALL_IMAGES += $(wildcard $(IMGDIR)/*.gif)
ALL_IMAGES += $(wildcard $(IMGDIR)/*.png)
ALL_IMAGES += $(wildcard $(IMGDIR)/*.xmi)
ALL_IMAGES += $(wildcard $(IMGDIR)/*.gnuplot)

.PHONY: all bib clean distclean k x e o

all: $(NOMBRE).pdf

bib: clean
	@echo "   Making dvi to get needed references..."
	@latex -halt-on-error -interaction=nonstopmode $(NOMBRE).tex &> .my_log || (cat .my_log && rm .my_log && exit 1)
	@rm .my_log
	@echo "   Generating bibliography..."
	@bibtool -q -x $(NOMBRE).aux $(BIBDIR)/*.bib > $(NOMBRE).bib 

# This is to really make the PDF file
$(NOMBRE).pdf: $(DEPENDENCIES) $(addsuffix .eps, $(basename $(ALL_IMAGES)))
	@echo "   Making dvi for first time..."
	@latex -halt-on-error -interaction=nonstopmode $(NOMBRE).tex &> .my_log || (cat .my_log && rm .my_log && exit 1)
	@rm .my_log
	@if [[ "${HAVE_BIB}" == "yes" ]]; then \
	echo "   Compiling references..." && \
	(bibtex $(NOMBRE) &> .my_log || (cat .my_log && rm .my_log && exit 1)) && \
	rm .my_log && \
	echo "   Re-making dvi including bibliography..." && \
	latex -halt-on-error -interaction=nonstopmode $(NOMBRE).tex &> .my_log || (cat .my_log && rm .my_log && exit 1) && \
	rm .my_log; \
	fi
	@echo "   Re-making dvi for satisfying references..."
	@latex $(NOMBRE).tex &> /dev/null
	@echo "   Generating final pdf..."
	@dvipdf $(NOMBRE).dvi &> /dev/null

# These are to construct the images :)
%.eps: %.dia
	@echo -n "   Converting $< to eps..."
	@dia -t eps -e $(basename $(basename $@)).eps $< &> /dev/null
	@echo " done!"

%.eps:: %.svg
	@echo -n "   Converting $< to eps..."
	@inkscape -E $(basename $(basename $@)).eps $< &> /dev/null
	@echo " done!"

%.eps:: %.jpg
	@echo -n "   Converting $< to eps..."
	@convert -quality 100 $< $@
	@echo " done!"

%.eps:: %.png
	@echo -n "   Converting $< to eps..."
	@convert -quality 100 $< $@
	@echo " done!"

%.eps:: %.gif
	@echo -n "   Converting $< to eps..."
	@convert -quality 100 $< $@
	@echo " done!"

%.eps:: %.gnuplot
	@echo -n "   Generating eps image from $<..."
	@gnuplot $< > $@
	@echo " done!"

%.eps:: %.xmi
	@echo -n "   Generating eps image from $<..."
	-@umbrello --export eps $< &> /dev/null
	@echo " done!"

# These are to clean the directory
clean:
	@echo "   Deleting auxiliary files..."
	-@rm -f $(NOMBRE).{aux,toc,log,tmp,dvi,idx,ilg,ind,bbl,blg,out,lof,lot} .my_log
	-@rm -f $(IMGDIR)/*~

distclean: clean
	@echo "   Deleting all generated files..."
	@-rm -f $(NOMBRE).pdf
	@-rm -f $(IMGDIR)/*.eps

# These are to display the pdf with some application
k: $(NOMBRE).pdf
	@if test "x$$(which kpdf)" == "x"; then \
	   echo "No 'kpdf' application found in your system, can't open $(NOMBRE).pdf file with kpdf."; \
	   exit 1; fi
	@echo "   Opening $(NOMBRE).pdf with kpdf..."
	@kpdf $(NOMBRE).pdf &> /dev/null &

x: $(NOMBRE).pdf
	@if test "x$$(which xpdf)" == "x"; then \
	   echo "No 'xpdf' application found in your system, can't open $(NOMBRE).pdf file with xpdf."; \
	   exit 1; fi
	@echo "   Opening $(NOMBRE).pdf with xpdf..."
	@xpdf $(NOMBRE).pdf &> /dev/null &

e: $(NOMBRE).pdf
	@if test "x$$(which evince)" == "x"; then \
	   echo "No 'evince' application found in your system, can't open $(NOMBRE).pdf file with evince."; \
	   exit 1; fi
	@echo "   Opening $(NOMBRE).pdf with evince..."
	@evince $(NOMBRE).pdf &> /dev/null &

o: $(NOMBRE).pdf
	@if test "x$$(which okular)" == "x"; then \
	   echo "No 'okular' application found in your system, can't open $(NOMBRE).pdf file with okular."; \
	   exit 1; fi
	@echo "   Opening $(NOMBRE).pdf with okular..."
	@okular $(NOMBRE).pdf &> /dev/null &
