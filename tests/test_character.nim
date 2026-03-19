import unittest
import "../src/entities/character"

suite "character":
  test "pip is 30x30 pink with doubleJump":
    let c = newCharacter("pip")
    check c.id == "pip"
    check c.width == 30
    check c.height == 30
    check c.color == (r: 255'u8, g: 182'u8, b: 193'u8)
    check c.ability == doubleJump

  test "luca is 25x40 yellow with floatAbility":
    let c = newCharacter("luca")
    check c.id == "luca"
    check c.width == 25
    check c.height == 40
    check c.ability == floatAbility

  test "bruno is 50x50 brown with heavy":
    let c = newCharacter("bruno")
    check c.width == 50
    check c.height == 50
    check c.ability == heavy

  test "cara is 20x45 light pink with wallJump":
    let c = newCharacter("cara")
    check c.width == 20
    check c.height == 45
    check c.ability == wallJump

  test "felix is 35x35 tan with coyoteTime":
    let c = newCharacter("felix")
    check c.width == 35
    check c.height == 35
    check c.ability == coyoteTime

  test "ivy is 28x42 teal with gracefulFall":
    let c = newCharacter("ivy")
    check c.width == 28
    check c.height == 42
    check c.color == (r: 0'u8, g: 128'u8, b: 128'u8)
    check c.ability == gracefulFall

  test "default fields on new character":
    let c = newCharacter("pip")
    check c.x == 0.0
    check c.y == 0.0
    check c.vx == 0.0
    check c.vy == 0.0
    check c.grounded == false
    check c.facingRight == true
