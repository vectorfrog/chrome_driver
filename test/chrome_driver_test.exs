defmodule ChromeDriverTest do
  use ExUnit.Case
  doctest ChromeDriver

  test "greets the world" do
    assert ChromeDriver.hello() == :world
  end
end
