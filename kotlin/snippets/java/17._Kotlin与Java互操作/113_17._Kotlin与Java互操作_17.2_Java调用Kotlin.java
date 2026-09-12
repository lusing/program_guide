// Java 调用
KotlinClass obj = new KotlinClass("World");
System.out.println(obj.getName());  // 属性生成 getter
System.out.println(obj.greet());

// 访问伴生对象
System.out.println(KotlinClass.VERSION);
KotlinClass.Companion.create("Test");  // 默认方式
KotlinClass.create("Test");            // 使用 @JvmStatic
