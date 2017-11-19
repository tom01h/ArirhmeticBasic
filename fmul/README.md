# FPU 乗算器の基礎

Verilatorで検証することを前提に、テストベンチはC++で記述しています。Verilatorが使える環境前提ですが、

## 実行法
`$ make` を実行すると sim/Vfmul_3 が出来ます。  
`$ sim/Vmul_3` を引数を1個与えて実行すると、引数で与えた回数繰り返してランダムで生成した入力を使った FPU 乗算を実行出来ます。  
好きな値をかけるには、引数を2個与えます。16進数で FPU フォーマットのデータを入力します。  
[Berkeley Testfloat](http://www.jhauser.us/arithmetic/TestFloat-3/doc/TestFloat-source.html) を使うには、`testfloat_gen -f32_mul` の出力を `sim/Vfmul_3` の標準入力から入力します。

```
$ {PATHto}/testfloat_gen -f32_mul | ./sim/Vfmul_3
```

## 履歴
- 正規化数のみ対応したバージョン [fmul_0.v を試す](https://github.com/tom01h/ArirhmeticBasic/tree/693c09ceb8ae089efbd1615c452d8cb918de9933)
  - 回路化を考えていない
  - オーバフロー・アンダーフローしたときはエラーになる
- 無限大と非数に対応したバージョン [fmul_1.v を試す](https://github.com/tom01h/ArirhmeticBasic/tree/8ad33b39799ef3a2221e2e284d9a17274d9757c2)  
  - Berkeley Testfloat に対応
  - 回路化を考えていない
  - サブノーマル数には対応していない
    -  `grep -v " 00[0-7]" | grep -v " 80[0-7]"` でエラーを除いてください
- サブノーマル数に対応した [fmul_2.v を試す](https://github.com/tom01h/ArirhmeticBasic/tree/bb4559d3afc2c1e403f03e3543225d0061f9c5e2)
  - Berkeley Testfloat をパス
  - 回路化を考えていない
- ノーマライズシフタを若干変更 fmul_3.v が最新です
  - 高速化目的だったけど、あまり効果なかった
