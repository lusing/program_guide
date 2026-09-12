// Java 接口
public interface ClickListener {
    void onClick(String id);
}

// Java 类
public class Button {
    public void setClickListener(ClickListener listener) { ... }
}
