package main

import (
	"bytes"
	"compress/gzip"
	"io"
	"testing"
)

func TestGzipRoundtrip(t *testing.T) {
	data := []byte(bytes.Repeat([]byte("重复内容"), 1000))
	z, err := GzipBytes(data)
	if err != nil {
		t.Fatal(err)
	}
	if len(z) >= len(data) {
		t.Errorf("高重复数据应显著变小：%d → %d", len(data), len(z))
	}
	back, err := GunzipBytes(z)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(back, data) {
		t.Error("往返内容不一致")
	}
}

func TestGzipTruncatedFails(t *testing.T) {
	z, err := GzipBytes([]byte("完整的一段数据完整的一段数据"))
	if err != nil {
		t.Fatal(err)
	}
	if _, err := GunzipBytes(z[:len(z)-4]); err == nil { // 砍掉尾部 CRC
		t.Error("缺尾部 CRC 的流应报错（Close 的价值）")
	}
}

func TestGzipLevels(t *testing.T) {
	data := bytes.Repeat([]byte("abcdefgh"), 10000)
	var best, fast []byte
	for _, lvl := range []int{gzip.BestCompression, gzip.BestSpeed} {
		var buf bytes.Buffer
		zw, _ := gzip.NewWriterLevel(&buf, lvl)
		zw.Write(data)
		zw.Close()
		if lvl == gzip.BestCompression {
			best = buf.Bytes()
		} else {
			fast = buf.Bytes()
		}
	}
	if len(best) >= len(fast) {
		t.Errorf("BestCompression(%d) 应不大于 BestSpeed(%d)", len(best), len(fast))
	}
}

func TestTarRoundtrip(t *testing.T) {
	in := map[string]string{"a.txt": "甲", "dir/b.txt": "乙"}
	tb, err := TarBytes(in)
	if err != nil {
		t.Fatal(err)
	}
	out, err := UntarBytes(tb)
	if err != nil {
		t.Fatal(err)
	}
	for k, v := range in {
		if out[k] != v {
			t.Errorf("tar 往返 %s = %q, want %q", k, out[k], v)
		}
	}
	if len(out) != len(in) {
		t.Errorf("条目数 = %d, want %d", len(out), len(in))
	}
}

func TestZipRoundtrip(t *testing.T) {
	in := map[string]string{"a.txt": "甲", "dir/b.txt": "乙"}
	zb, err := ZipBytes(in)
	if err != nil {
		t.Fatal(err)
	}
	out, err := UnzipBytes(zb)
	if err != nil {
		t.Fatal(err)
	}
	for k, v := range in {
		if out[k] != v {
			t.Errorf("zip 往返 %s = %q, want %q", k, out[k], v)
		}
	}
}

// doubleLayer 验证 .tar.gz 的两层管道思维。
func TestTarGzDoubleLayer(t *testing.T) {
	in := map[string]string{"x": "y"}
	tb, _ := TarBytes(in)
	gz, err := GzipBytes(tb)
	if err != nil {
		t.Fatal(err)
	}
	zr, err := gzip.NewReader(bytes.NewReader(gz))
	if err != nil {
		t.Fatal(err)
	}
	defer zr.Close()
	untarred, err := UntarBytes(mustReadAll(zr))
	if err != nil || untarred["x"] != "y" {
		t.Errorf("双层解包失败：%v", err)
	}
}

func mustReadAll(r io.Reader) []byte {
	b, _ := io.ReadAll(r)
	return b
}
