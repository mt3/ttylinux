all:	pdf ps html

dvi:
	latex User_Guide.tex
	latex User_Guide.tex
	latex User_Guide.tex

pdf:
	pdflatex User_Guide.tex
	pdflatex User_Guide.tex
	pdflatex User_Guide.tex

ps:	dvi
	dvips -o User_Guide.ps User_Guide.dvi

temp.tex:
	sed -e 's:\\url{:{\\tt :g'					\
		-e 's:\([^\\]\)_:\1\\_:g'				\
		-e "s:begin{lstlisting}:begin{verbatim}:g"		\
		-e "s:end{lstlisting}:end{verbatim}:g"			\
		<User_Guide.tex >temp.tex
	latex temp.tex

html_multi:
	latex2html -local_icons -nocontents_in_navigation -nofootnode	\
		-noaddress -noinfo -show_section_numbers 		\
		-html_version 4.0 -lcase_tags -dir multi -mkdir temp.tex

html_single:
	latex2html -split 0 -local_icons -nonavigation -nofootnode	\
		-noaddress -noinfo -show_section_numbers		\
		-html_version 4.0 -lcase_tags -dir single -mkdir temp.tex
	sed -e 's:temp.html:User_Guide.html:'				\
		<single/index.html >single/User_Guide.html
	rm single/index.html

html:	temp.tex html_multi html_single
	find . -name "*.html" -exec sed -e 's|\\_|_|g' -i {} \;

clean:
	rm -f temp.*
	rm -f User_Guide.aux User_Guide.log User_Guide.toc User_Guide.dvi

distclean: clean
	rm -f User_Guide.ps User_Guide.pdf
	rm -rf single multi

