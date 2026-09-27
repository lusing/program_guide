// 31_archive：gzip 压缩、tar 打包、zip 归档——全部在内存里做往返。
// 对照 docs/31-archive.md。
package main

import (
	"archive/tar"
	"archive/zip"
	"bytes"
	"compress/gzip"
	"fmt"
	"io"
	"math/rand/v2"
)

// GzipBytes 压缩（Close 必须调：尾部 CRC 在那时才写）。
func GzipBytes(data []byte) ([]byte, error) {
	var buf bytes.Buffer
	zw := gzip.NewWriter(&buf)
	if _, err := zw.Write(data); err != nil {
		return nil, err
	}
	if err := zw.Close(); err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}

// GunzipBytes 解压。
func GunzipBytes(z []byte) ([]byte, error) {
	zr, err := gzip.NewReader(bytes.NewReader(z))
	if err != nil {
		return nil, err
	}
	defer zr.Close()
	return io.ReadAll(zr)
}

// TarBytes 把多文件打包成 tar 字节流。
func TarBytes(files map[string]string) ([]byte, error) {
	var buf bytes.Buffer
	tw := tar.NewWriter(&buf)
	for name, content := range files {
		hdr := &tar.Header{
			Name:     name,
			Mode:     0o644,
			Size:     int64(len(content)),
			Typeflag: tar.TypeReg,
		}
		if err := tw.WriteHeader(hdr); err != nil {
			return nil, err
		}
		if _, err := tw.Write([]byte(content)); err != nil {
			return nil, err
		}
	}
	if err := tw.Close(); err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}

// UntarBytes 解包回 map。
func UntarBytes(b []byte) (map[string]string, error) {
	tr := tar.NewReader(bytes.NewReader(b))
	files := make(map[string]string)
	for {
		hdr, err := tr.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return nil, err
		}
		if hdr.Typeflag != tar.TypeReg {
			continue
		}
		content, err := io.ReadAll(tr) // 只读当前条目的字节
		if err != nil {
			return nil, err
		}
		files[hdr.Name] = string(content)
	}
	return files, nil
}

// ZipBytes 归档 + 压缩。
func ZipBytes(files map[string]string) ([]byte, error) {
	var buf bytes.Buffer
	zw := zip.NewWriter(&buf)
	for name, content := range files {
		w, err := zw.Create(name)
		if err != nil {
			return nil, err
		}
		if _, err := w.Write([]byte(content)); err != nil {
			return nil, err
		}
	}
	if err := zw.Close(); err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}

// UnzipBytes 解归档。
func UnzipBytes(b []byte) (map[string]string, error) {
	zr, err := zip.NewReader(bytes.NewReader(b), int64(len(b)))
	if err != nil {
		return nil, err
	}
	files := make(map[string]string)
	for _, f := range zr.File {
		rc, err := f.Open()
		if err != nil {
			return nil, err
		}
		content, err := io.ReadAll(rc)
		rc.Close() // 当轮显式关，不等 defer 堆到循环结束
		if err != nil {
			return nil, err
		}
		files[f.Name] = string(content)
	}
	return files, nil
}

func main() {
	fmt.Println("== gzip：压缩比看重复度 ==")
	text := bytes.Repeat([]byte("Go 语言标准库，示例驱动的学习路径。\n"), 100)
	z, _ := GzipBytes(text)
	back, _ := GunzipBytes(z)
	fmt.Printf("原始 %d 字节 → gzip %d 字节（%.1f%%）；往返一致: %v\n",
		len(text), len(z), 100*float64(len(z))/float64(len(text)), bytes.Equal(back, text))
	// 真·随机数据：固定种子的 PCG 流逐字节填（rand/v2 没有 Read，自己填）
	rr := rand.New(rand.NewPCG(1, 2))
	random := make([]byte, 4096)
	for i := range random {
		random[i] = byte(rr.IntN(256))
	}
	zr2, _ := GzipBytes(random)
	fmt.Printf("随机数据：4096 → %d 字节（压不动是正常的）\n", len(zr2))

	fmt.Println("== tar：多文件打包 ==")
	in := map[string]string{
		"readme.md": "# 示例\n",
		"src/a.go":  "package main\n",
		"src/b.go":  "package main\n",
	}
	tb, _ := TarBytes(in)
	out, err := UntarBytes(tb)
	if err != nil {
		fmt.Println("Untar:", err)
		return
	}
	fmt.Printf("%d 字节的 tar，含 %d 个文件，内容一致: %v\n", len(tb), len(out), fmt.Sprint(in) == fmt.Sprint(out))

	fmt.Println("== zip：归档 + 压缩 ==")
	zb, _ := ZipBytes(in)
	zout, err := UnzipBytes(zb)
	if err != nil {
		fmt.Println("Unzip:", err)
		return
	}
	fmt.Printf("%d 字节的 zip，内容一致: %v\n", len(zb), fmt.Sprint(in) == fmt.Sprint(zout))

	fmt.Println("== .tar.gz 双层管道：tar 外面套 gzip ==")
	gz, _ := GzipBytes(tb)
	fmt.Printf("tar %d → tar.gz %d 字节（%.1f%%）\n", len(tb), len(gz), 100*float64(len(gz))/float64(len(tb)))
}
