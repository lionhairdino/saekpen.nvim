# 색펜 SaekPen
※ Saek is the Korean word for color.

네오빔에서 쓸 색연필

![SaekPen](saekpen0.01.gif)
```default
saekpen
├── LICENSE
├── lua
│   └── saekpen
│       ├── deps
│       └── init.lua
├── plugin
│   └── saekpen.vim
└── Readme.md

5 directories, 4 files
```
### 사용법
```default
:SaekMode
```
위 명령어로 색모드에 진입후\
펜 색깔 선택 - `1`,`2`,`3`,`4`,`5`,`6`,`7`,`8`\
비주얼 모드에서 텍스트를 선택 후 숫자키를 눌러 색깔을 정하고 `<Enter>`키로 색깔 확정\
노멀 모드에서 숫자키로 바로 원하는 색깔의 비주얼 모드로 진입, 텍스트 선택 후 `<Enter>`키로 색깔 확정

### todo
- 색 편집 결과 저장
- ANSI Escape Code로 뽑아내어 클립보드에 저장 (디스코드에 붙이는 용도)
- 색깔 인디케이터
 
### Vim.kr
Lua를 처음 만지며, 처음으로 네오빔 플러그인을 개발하고 있어 어설픈 게 많습니다. 개발 중 막히는 것들은 대부분 Vim.kr에 계신 분들께 답을 얻고 있습니다. 빔, 네오빔에 관심 있는 분은 [Vim.kr](http://vim.kr/)을 방문해 보세요.

