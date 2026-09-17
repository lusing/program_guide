package store

import (
	"errors"
	"slices"
	"testing"
)

func TestSetGetKeys(t *testing.T) {
	s := &Store{} // 零值可用
	if _, err := s.Get("x"); !errors.Is(err, ErrNotFound) {
		t.Errorf("缺键应得 ErrNotFound，得 %v", err)
	}
	s.Set("b", "2")
	s.Set("a", "1")
	if v, err := s.Get("a"); err != nil || v != "1" {
		t.Errorf("Get(a) = (%q,%v)", v, err)
	}
	if got := s.Keys(); !slices.Equal(got, []string{"a", "b"}) {
		t.Errorf("Keys = %v, want [a b]", got)
	}
	s.Delete("a")
	if got := s.Keys(); !slices.Equal(got, []string{"b"}) {
		t.Errorf("Delete 后 Keys = %v", got)
	}
	s.Delete("不存在") // 幂等：不报错
}
