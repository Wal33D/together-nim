import unittest
import "../src/entities/character"
import "../src/constants"

suite "character":
  test "pip with doubleJump":
    let c = newCharacter("pip")
    check c.id == "pip"
    check c.width == 24
    check c.height == 24
    check c.color == PIP_COLOR
    check c.ability == doubleJump

  test "luca with floatAbility":
    let c = newCharacter("luca")
    check c.id == "luca"
    check c.width == 28
    check c.height == 28
    check c.ability == floatAbility

  test "bruno with heavy":
    let c = newCharacter("bruno")
    check c.width == 40
    check c.height == 40
    check c.ability == heavy

  test "cara with wallJump":
    let c = newCharacter("cara")
    check c.width == 20
    check c.height == 20
    check c.ability == wallJump

  test "felix with coyoteTime":
    let c = newCharacter("felix")
    check c.width == 20
    check c.height == 50
    check c.ability == coyoteTime

  test "ivy with gracefulFall":
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

  test "new character is not dying or respawning":
    let c = newCharacter("pip")
    check c.isDying() == false
    check c.isRespawning() == false
    check c.deathTimer == 0.0
    check c.respawnTimer == 0.0
    check c.deathFlashCount == 0

  test "isDying when deathTimer positive":
    var c = newCharacter("pip")
    c.deathTimer = 0.5
    check c.isDying() == true

  test "isRespawning when respawnTimer positive":
    var c = newCharacter("pip")
    c.respawnTimer = 0.3
    check c.isRespawning() == true

  test "deathVisible flashes on/off during death":
    var c = newCharacter("pip")
    # At the start of death (deathTimer=0.5, elapsed=0), first 50ms is visible
    c.deathTimer = 0.5
    check c.deathVisible() == true
    # At 75ms elapsed (deathTimer=0.425), in the off phase (50-100ms)
    c.deathTimer = 0.425
    check c.deathVisible() == false
    # At 110ms elapsed (deathTimer=0.39), in the on phase of second flash
    c.deathTimer = 0.39
    check c.deathVisible() == true

  test "deathVisible hidden after 300ms flash phase":
    var c = newCharacter("pip")
    # After 300ms of flashing, sprite should be hidden
    c.deathTimer = 0.15  # elapsed = 350ms, past the 300ms flash window
    check c.deathVisible() == false

  test "respawnAlpha fades from 0 to 255":
    var c = newCharacter("pip")
    c.respawnTimer = 0.3
    check c.respawnAlpha() == 0'u8
    c.respawnTimer = 0.15
    let mid = c.respawnAlpha()
    check mid > 100'u8
    check mid < 200'u8
    c.respawnTimer = 0.0
    check c.respawnAlpha() == 255'u8
