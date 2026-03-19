import unittest
import "../src/entities/character"
import "../src/constants"

suite "character":
  test "pip is 30x30 with doubleJump":
    let c = newCharacter("pip")
    check c.id == "pip"
    check c.width == 30
    check c.height == 30
    check c.ability == doubleJump

  test "luca is 25x40 with floatAbility":
    let c = newCharacter("luca")
    check c.id == "luca"
    check c.width == 25
    check c.height == 40
    check c.ability == floatAbility

  test "bruno is 50x50 with heavy":
    let c = newCharacter("bruno")
    check c.width == 50
    check c.height == 50
    check c.ability == heavy

  test "cara is 20x45 with wallJump":
    let c = newCharacter("cara")
    check c.width == 20
    check c.height == 45
    check c.ability == wallJump

  test "felix is 35x35 with coyoteTime":
    let c = newCharacter("felix")
    check c.width == 35
    check c.height == 35
    check c.ability == coyoteTime

  test "ivy is 28x42 with gracefulFall":
    let c = newCharacter("ivy")
    check c.width == 28
    check c.height == 42
    check c.ability == gracefulFall

  test "default fields on new character":
    let c = newCharacter("pip")
    check c.x == 0.0
    check c.y == 0.0
    check c.grounded == false
    check c.facingRight == true
    check c.jumpCount == 0
