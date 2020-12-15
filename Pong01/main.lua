
push = require 'push'
Class = require 'class'
require 'Paddle' 
require 'Ball'

--Size of the window
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

--Paddle speed
PADDLE_TEMPO = 200
--AI speed
AI_TEMPO = 200

function love.load()
   
    love.graphics.setDefaultFilter('nearest', 'nearest')

    love.window.setTitle('Pong')
    math.randomseed(os.time())

    --costumized our font into a retro style
    smallFont = love.graphics.newFont('font.ttf', 12)
    largeFont = love.graphics.newFont('font.ttf', 16)
    scoreFont = love.graphics.newFont('font.ttf', 32)

    love.graphics.setFont(smallFont)

    --set up our sound effects
    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/pad_hit.wav', 'static'),
        ['score'] = love.audio.newSource('sounds/score.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static')
    }

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true
    })
    --Initial score
    player1Score = 0
    player2Score = 0
    
    servingPlayer = 1

    player1 = Paddle(10, 30, 10, 40)
    player2 = Paddle(VIRTUAL_WIDTH - 15, VIRTUAL_HEIGHT - 30, 10, 40)
    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)

    gameState = 'start'
end

function love.resize(w, h)
    push:resize(w, h)
end

function love.update(dt)
    if gameState == 'serve' then
     
        ball.dy = math.random(-50, 50)
        if servingPlayer == 1 then
            ball.dx = math.random(140, 200)
        else
            ball.dx = -math.random(140, 200)
        end
    elseif gameState == 'play' then
        if ball.y >= player2.y + 5 and ball.y + 4 <= player2.y + 15 then
            player2.dy = 0
        else
            if player2.y + 5 > ball.y then
                player2.dy = -AI_TEMPO
            elseif player2.y + 12 < ball.y + 4 then
                player2.dy = AI_TEMPO
            end
        end    

        if ball:collides(player1) then
            ball.dx = -ball.dx * 1.03
            ball.x = player1.x + 5
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end

            sounds['paddle_hit']:play()
        end
        if ball:collides(player2) then
            ball.dx = -ball.dx * 1.03
            ball.x = player2.x - 4
            player2.dy = 0
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end

            sounds['paddle_hit']:play()
        end

        --up
        if ball.y <= 12 then
            ball.y = 12
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        --down
        if ball.y >= VIRTUAL_HEIGHT - 16 then
            ball.y = VIRTUAL_HEIGHT - 16
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        --right side
        if ball.x < 12 then
            servingPlayer = 1
            player2Score = player2Score + 1
            sounds['score']:play()

            if player2Score == 10 then
                winningPlayer = 2
                gameState = 'done'
            else
                gameState = 'serve'
    
                ball:reset()
            end
        end

        --left side
        if ball.x > VIRTUAL_WIDTH then
            servingPlayer = 2
            player1Score = player1Score + 1
            sounds['score']:play()

            if player1Score == 10 then
                winningPlayer = 1
                gameState = 'done'
            else
                gameState = 'serve'
                ball:reset()
            end
        end
    end

    --player 1 
    if love.keyboard.isDown('w') then
        player1.dy = -PADDLE_TEMPO
    elseif love.keyboard.isDown('s') then
        player1.dy = PADDLE_TEMPO
    else
        player1.dy = 0
    end

    if gameState == 'play' then
        ball:update(dt)
    end

    player1:update(dt)
    player2:update(dt)
end

function love.keypressed(key)
    --If we press 'escape', it will automatically quit the application.
    if key == 'escape' then
        love.event.quit()

    --We need to press 'space' to start and do the serve.
    elseif key == 'space' then
        if gameState == 'start' then
            gameState = 'serve'
        elseif gameState == 'serve' then
            gameState = 'play'
        elseif gameState == 'done' then
            gameState = 'serve'

            ball:reset()

            player1Score = 0
            player2Score = 0

            if winningPlayer == 1 then
                servingPlayer = 2
            else
                servingPlayer = 1
            end
        end
    end
end

function love.draw()

    push:apply('start')

    love.graphics.clear(40/255,45/255,52/255,1)
    
    if gameState == 'start' then
        love.graphics.setFont(largeFont)
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.printf('PONG', 0, 20, VIRTUAL_WIDTH, 'center')
        love.graphics.rectangle('line', VIRTUAL_WIDTH / 2 - 160, VIRTUAL_HEIGHT / 2 - 40, 320, 80)
        love.graphics.printf('Press Space to play!', 0, VIRTUAL_HEIGHT / 2 - 6, VIRTUAL_WIDTH, 'center')

    elseif gameState == 'play' then
        ball:render()

    elseif gameState == 'serve' then
        love.graphics.setFont(smallFont)
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve!", 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Space to serve!', 0, 20, VIRTUAL_WIDTH, 'center')
        displayScore()

    elseif gameState == 'done' then
        love.graphics.setFont(largeFont)
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.printf('Player ' .. tostring(winningPlayer) .. ' wins!', 0, 150, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Space to restart!', 0, 170, VIRTUAL_WIDTH, 'center')
        displayScore()

    end

    player1:render()
    player2:render()

    displayFPS()

    push:apply('end')
end

-- Displays the FPS 
function displayFPS()
    love.graphics.setFont(smallFont)
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
end

-- Displays the score
function displayScore()
    --The font color with the higher score will display blue and the lower score is red, when even, white is displayed.
    love.graphics.setFont(scoreFont)
    if player1Score > player2Score then
        love.graphics.setColor(0, 0, 255, 255)
    elseif player1Score < player2Score then
        love.graphics.setColor(255, 0, 0, 255)
    else
        love.graphics.setColor(255, 255, 255, 255)
    end

    --The paddle color will depend on the color of the higher score.
    love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 50,VIRTUAL_HEIGHT / 3)
    if player1Score < player2Score then
        love.graphics.setColor(0, 0, 255, 255)
    elseif player1Score > player2Score then
        love.graphics.setColor(255, 0, 0, 255)
    else
        love.graphics.setColor(255, 255, 255, 255)
    end
    
    love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + 30, VIRTUAL_HEIGHT / 3)
end

