# OPAM packages needed to build tests.
OPAM_PACKAGES="cmdliner"


case "$OCAML_VERSION,$OPAM_VERSION" in
3.12.1,1.0.0) ppa=avsm/ocaml312+opam10 ;;
3.12.1,1.1.0) ppa=avsm/ocaml312+opam11 ;;
4.00.1,1.0.0) ppa=avsm/ocaml40+opam10 ;;
4.00.1,1.1.0) ppa=avsm/ocaml40+opam11 ;;
4.01.0,1.0.0) ppa=avsm/ocaml41+opam10 ;;
4.01.0,1.1.0) ppa=avsm/ocaml41+opam11 ;;
*) echo Unknown $OCAML_VERSION,$OPAM_VERSION; exit 1 ;;
esac

echo "yes" | sudo add-apt-repository ppa:$ppa
sudo apt-get update -qq
sudo apt-get install -qq ocaml ocaml-native-compilers camlp4-extra opam gnuplot m4
export OPAMYES=1
export OPAMVERBOSE=1
echo OCaml version
ocaml -version
echo OPAM versions
opam --version
opam --git-version

opam init 
opam install ${OPAM_PACKAGES}

eval `opam config -env`

# Post-boilerplate
git clone http://github.com/robhoes/elo-ladder
cd elo-ladder
make
./ladder print --gh-pages --title "XenServer Chess Ladder" ../players ../games --reverse > index.md
./ladder json ../players ../games > ladder.json
(echo set terminal png; ./ladder history --format=gnuplot ../players ../games) | gnuplot > ladder.png

if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
  echo -e "Starting to update gh-pages\n"

  #copy data we're interested in to other place
  cp index.html $HOME/index.html
  cp ladder.js $HOME/ladder.js
  cp ladder.json $HOME/ladder.json
  cp ladder.png $HOME/ladder.png
  cp style.css $HOME/style.css

  #go to home and setup git
  cd $HOME
  git config --global user.email "travis@travis-ci.org"
  git config --global user.name "Travis"

  #using token clone gh-pages branch
  git clone --quiet --branch=gh-pages https://${GH_TOKEN}@github.com/robhoes/elo-ladder-games.git  gh-pages > /dev/null

  #go into directory and copy data we're interested in to that directory
  cd gh-pages
  cp -f $HOME/index.html .
  cp -f $HOME/ladder.js .
  cp -f $HOME/ladder.json .
  cp -f $HOME/ladder.png .
  cp -f $HOME/style.css .

  #add, commit and push files
  git commit --allow-empty -am "Travis build $TRAVIS_BUILD_NUMBER pushed to gh-pages"
  git push -fq origin gh-pages > /dev/null

  echo -e "Updated Rob's gh-pages with latest ladder\n"
fi
