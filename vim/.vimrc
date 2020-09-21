" バックスペースで文字削除を有効にする
set backspace=indent,eol,start
" シンタックスハイライトを有効にする
syntax on
" 行数を表示する
set number
" タブキーを押した際にタブ文字の代わりにスペースを入れる
set expandtab
" タブ文字の表示幅
set tabstop=2
" 改行時に前の行のインデントを継続する
set autoindent
"タブキー押下時に挿入される文字幅
set softtabstop=2
"自動インデントに使われる空白の数
set shiftwidth=2
" バックアップファイルを作らない
set nobackup
" タブ、半角スペース、改行を可視化
set list
set listchars=tab:»-,trail:-,eol:↲,extends:»,precedes:«,nbsp:%
" previmの設定
let g:previm_open_cmd = 'open -a Safari'
" deinの設定ここから
if &compatible
  set nocompatible
endif
set runtimepath+=~/.vim/dein/repos/github.com/Shougo/dein.vim

if dein#load_state('~/.vim/dein')
  call dein#begin('~/.vim/dein')

  call dein#add('~/.vim/dein/repos/github.com/Shougo/dein.vim')
  call dein#add('Shougo/neocomplete.vim')
  call dein#add('kannokanno/previm')

  call dein#end()
  call dein#save_state()
endif

filetype plugin indent on
syntax enable
" deinの設定ここまで
