#  FMA 演算器
## 状況

本来ならもっと CSA を使ってキャリー伝搬を減らすべきなのですが、記述が面倒なので CPA 使いまくりです。

あと、bfloat16 の方はパイプ化できていません。

## 準備

#### TestFloat をビルド
```
$ cd ${path_to_fam}/berkeley-softfloat-3/build/Linux-x86_64-GCC/
$ make
$ cd ${path_to_fam}/berkeley-testfloat-3/build/Linux-x86_64-GCC/
$ make
```

#### TestFloat の確認
単精度 FMA の場合
```
$ ${path_to_fam}/berkeley-testfloat-3/build/Linux-x86_64-GCC/testfloat_gen f32_mulAdd
```
こんな感じのが出てくればOK  
意味は、```入力1 入力2 演入力3 演算結果 フラグ``` の順です。

```
8683F7FF C07F3FFF 00000000 07839504 01
00000000 00000000 3C072C85 3C072C85 00
9EDE38F7 3E7F7F7F DF7EFFFF DF7EFFFF 01
(略)
```

## Float32 の検証の実行

1分ほどかかります。ログファイルは400MBくらいになります。波形は最初のほうしか出ません。

```
$ cd ${path_to_fam}
$ make
$ ./berkeley-testfloat-3/build/Linux-x86_64-GCC/testfloat_gen f32_mulAdd | ./sim/Vfmad > LOG
```

## bfloat16 の検証の実行

波形は最初のほうしか出ません。

```
$ cd ${path_to_fam}
$ make TB=fmacc_tb.cpp
$ ./berkeley-testfloat-3/build/Linux-x86_64-GCC/testfloat_gen f32_mulAdd | ./sim/Vfmad > LOG
```