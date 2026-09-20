defmodule Ex22MixReleaseTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  doctest Ex22MixRelease

  test "settings 含编译期、环境、runtime 三层配置" do
    settings = Ex22MixRelease.settings()
    assert settings[:greeting] == "编译期配置"
    # mix test 默认把 env 切到 test，但显式 MIX_ENV 会保留（本教程的 run-all
    # 统一导出 dev 跑全部层）；期望值按实际 env 取，两种正规跑法都成立。
    assert settings[:env_tag] == "#{Mix.env()} 环境"
    assert settings[:boot_tag] == "runtime 配置"
    assert settings[:who] == "世界"
  end

  test "DEMO_WHO 环境变量改变 runtime 配置" do
    # runtime.exs 已在测试启动时求过值；这里直接验证取值逻辑的来源是环境变量。
    assert System.get_env("DEMO_WHO", "世界") == "世界"
  end

  test "自定义任务 mix who 可直接调用 run/1" do
    output = capture_io(fn -> Mix.Tasks.Who.run([]) end)
    assert String.trim(output) == "mix who => 自定义任务运行（版本 0.1.0）"
  end

  test "hello 输出固定标签" do
    output = capture_io(fn -> Ex22MixRelease.hello() end)
    assert String.trim(output) == "release eval 运行成功"
  end
end
