
all: compile 

compile: 
	latexmk -g -pdf 00_project.tex

presentation: 
	latexmk -g -pdf presentation.tex

clean:
	latexmk -c

clean_all: clean
	latexmk -C

run: 
	atril *.pdf &> /dev/null &
