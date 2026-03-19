import unittest
import "../src/entities/character"
import "../src/constants"

suite "character":
  test "pip is 24x24 pink with doubleJump":
    let c = newCharacter("pip")
    check c.id == "pip"
    check c.width == 24
    check c.height == 24
    check c.color == PIP_COLOR
    check c.ability == doubleJump

  test "luca is 28x28 yellow with floatAbility":
    let c = newCharacter("luca")
    check c.id == "luca"
    check c.width == 28
    check c.height == 28
    check c.ability == floatAbility

  test "bruno is 40x40 brown with heavy":
    let c = newCharacter("bruno")
    check c.width == 40
    check c.height == 40
    check c.ability == heavy

  test "cara is 20x20 with wallJump":
    let c = newCharacter("cara")
    check c.width == 20
    check c.height == 20
    check c.ability == wallJump

  test "felix is 20x50 with coyoteTime":
    let c = newCharacter("felix")
    check c.width == 20
    check c.height == 50
    check c.ability == coyoteTime

  test "ivy is 28x28 with gracefulFall":
    let c = newCharacter("ivy")
    check c.width == 28
    check c.height == 28
    check c.color == IVY_COLOR
    check c.ability == gracefulFall

  test "default fields on new character":
    let c = newCharacter("pip")
    check c.x == 0.0
    check c.y == 0.0
    check c.grounded == false
    check c.facingRight == true
    check c.jumpCount == 0
