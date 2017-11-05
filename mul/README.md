# 乗算器の基礎

Verilatorで検証することを前提に、テストベンチはC++で記述しています。32bitの符号あり、符号なしの乗算に対応しています。テストベンチは符号ありにしか対応していませんが…
Verilatorが使える環境前提ですが、

## 実行法
`$ make` を実行すると sim/Vmul_3 が出来ます。  
`$ sim/Vmul_3` を引数なしで実行すると、ランダムで生成した入力を使った乗算を 1000 回実行します。  
好きな回数で実行する場合は、引数を1個与えます。  
好きな値をかけるには、引数を2個与えます。  
引数は10進数ですが、結果の表示は16進数なので、バグの再現実行が面倒くさいです。

## 履歴
- 符号拡張を省略する工夫なしのバージョン [mul_0.v を試す](https://github.com/tom01h/ArirhmeticBasic/tree/9561c709123053e277ffcfa270fe1b4287a8fa39)
- ループで部分積を足しこむ前のバージョン [mul_1.v を試す](https://github.com/tom01h/ArirhmeticBasic/tree/effeaadcf53c03a44681a21fde629128f38a5413)  
  - 分かりやすさ最優先の記述です
- 3入力加算器を使って足しこむバージョン [mul_2.v を試す](https://github.com/tom01h/ArirhmeticBasic/tree/71738dc101393e5d2c036393db2068ea56ed745d)
  - 1サイクル毎に2個づつ部分積を減らしていくので、8サイクルで32bitの乗算が完了します
  - パイプライン動作の検証はできません
- V-Scale で使っている乗算器 [mul_3.v を試す](https://github.com/tom01h/ArirhmeticBasic/tree/f6357876dc8384df1c68a328dceea705b1ca4d32)
  - 5サイクルで32bit乗算が完了します
  - パイプライン動作の検証はできません
