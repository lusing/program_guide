//! geometry：库 crate 示例——对外暴露 pub API，自带单元测试。

/// 圆面积
pub fn circle_area(r: f64) -> f64 {
    std::f64::consts::PI * r * r
}

/// 矩形面积
pub fn rect_area(w: f64, h: f64) -> f64 {
    w * h
}

/// 模块级 feature 门控：只有开启 `advanced` feature 才编译进产物。
/// 调用方：geometry = { path = "...", features = ["advanced"] }
#[cfg(feature = "advanced")]
pub mod advanced {
    /// 任意简单多边形面积（鞋带公式）
    pub fn polygon_area(points: &[(f64, f64)]) -> f64 {
        if points.len() < 3 {
            return 0.0;
        }
        let mut s = 0.0;
        for i in 0..points.len() {
            let (x1, y1) = points[i];
            let (x2, y2) = points[(i + 1) % points.len()];
            s += x1 * y2 - x2 * y1;
        }
        (s / 2.0).abs()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn basic_areas() {
        assert!((circle_area(1.0) - std::f64::consts::PI).abs() < 1e-12);
        assert_eq!(rect_area(3.0, 4.0), 12.0);
    }

    #[cfg(feature = "advanced")]
    #[test]
    fn shoelace() {
        let square = [(0.0, 0.0), (4.0, 0.0), (4.0, 4.0), (0.0, 4.0)];
        assert_eq!(advanced::polygon_area(&square), 16.0);
    }
}
