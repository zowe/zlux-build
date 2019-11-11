#! /bin/sh
# This program and the accompanying materials are
# made available under the terms of the Eclipse Public License v2.0 which accompanies
# this distribution, and is available at https://www.eclipse.org/legal/epl-v20.html
# 
# SPDX-License-Identifier: EPL-2.0
# 
# Copyright Contributors to the Zowe Project.

#TODO: add specific files without extensions

if [ $# -eq 0 ]
    then
    echo "Usage: $0 DirectoryToTag"
    exit 1
fi

start_path=$(pwd)
cd $1

#Ascii files
echo "Tagging files for ISO8859-1"

find . \( \
-name "*.1" -o \
-iname "AUTHORS" -o \
-iname ".babelrc" -o \
-iname "*.bat" -o \
-iname "*.bnf" -o \
-iname "*.bsd" -o \
-iname "*.cer" -o \
-iname "CODEOWNERS" -o \
-iname "*.coffee" -o \
-iname "*.conf" -o \
-iname "*.def" -o \
-iname ".editorconfig" -o \
-iname "*.el" -o \
-iname ".eslintignore" -o \
-iname ".eslintrc" -o \
-iname "*.gradle" -o \
-iname "*.in" -o \
-iname "*.info" -o \
-iname "*.js" -o \
-iname "Jenkinsfile" -o \
-iname ".jscsrc" -o \
-iname ".jshintignore" -o \
-iname ".jshintrc" -o \
-iname "*.json" -o \
-iname "*.jst" -o \
-iname "*.key" -o \
-iname "LICENSE" -o \
-iname "*.lock" -o \
-iname "*.log" -o \
-iname "*.ls" -o \
-iname ".mailmap" -o \
-iname "Makefile" -o \
-iname "*.map" -o \
-iname "*.markdown" -o \
-iname "*.md" -o \
-iname ".npmignore" -o \
-iname ".nycrc" -o \
-iname "*.opts" -o \
-iname "*.patch" -o \
-iname "*.ppf" -o \
-iname "*.properties" -o \
-iname "README" -o \
-iname "*.targ" -o \
-iname ".tm_properties" -o \
-iname "*.ts" -o \
-iname "*.tst" -o \
-iname "*.txt" -o \
-iname "*.xml" -o \
-iname "*.yaml" -o \
-iname "*.yml" \
\) -exec chtag -tc ISO8859-1 {} \;

#UTF-8 files
#UTF-8 behavior seems broken. Best to leave these as binary instead.
#echo "Tagging files for UTF-8"
echo "Tagging files for UTF-8 as binary"

find . \( \
-iname "*.css" -o \
-iname "*.jsx" -o \
-iname "*.html" -o \
-iname "*.tsx" -o \
-iname "*.xlf" \
\) -exec chtag -b {} \;

#Binary files
echo "Tagging files for binary"

find . \( \
-iname "*.br" -o \
-iname "*.bz2" -o \
-iname "*.crx" -o \
-iname "*.eot" -o \
-iname "*.gif" -o \
-iname "*.gz" -o \
-iname "*.jar" -o \
-iname "*.jpg" -o \
-iname "*.mpg" -o \
-iname "*.mp3" -o \
-iname "*.mp4" -o \
-iname "*.m4v" -o \
-iname "*.ogg" -o \
-iname "*.ogm" -o \
-iname "*.pax" -o \
-iname "*.p12" -o \
-iname "*.pdf" -o \
-iname "*.png" -o \
-iname "*.svg" -o \
-iname "*.ttf" -o \
-iname "*.woff" -o \
-iname "*.woff2" -o \
-name "zssServer" \
\) -exec chtag -b {} \;

#Convert to ebcdic
#find . \( \
#-iname ".gitmodules" -o \
#-iname "*.sh" \
#\) -exec iconv -f iso8859-1 -t 1047 {} \;

#Ebcdic files
echo "Tagging files for IBM-1047"

find . \( \
-iname ".gitmodules" -o \
-iname *.jcl" -o \
-iname "*.sh" \
\) -exec chtag -tc 1047 {} \;


cd $start_path
