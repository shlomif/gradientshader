scale = 4
function love.load(args)
   love.graphics.setDefaultImageFilter("nearest","nearest")
   love.graphics.setMode(640, 480, false, false)
   base = load_image("bg.png")
   progressmap = load_image("bg-progressmap.png")

   load_shader()

   next_time = love.timer.getMicroTime()
   progress_time = 255
   min_dt = 1/60
   love.graphics.setPixelEffect(pixeleffect)
end

function love.update(dt)
   next_time = next_time + min_dt
   progress_time = progress_time - 40*dt
   if progress_time < 0.0 then
      progress_time = 255
   end
end

function load_image(file)
   local full_path = love.filesystem.getWorkingDirectory() .. "/" .. file
   local fh = assert(io.open(full_path, "rb"))
   local image_data = fh:read("*a")
   local file_data = love.filesystem.newFileData(image_data, "file.png", "file")
   return love.graphics.newImage(love.image.newImageData(file_data))
end

function love.keypressed(key)
   if key == "escape" then
      love.event.push("quit")
   end
end

function love.draw()
   -- This frame cap code is lifted verbatim from the docs.
   local cur_time = love.timer.getMicroTime()
   if next_time <= cur_time then
      next_time = cur_time
      return
   end
   love.timer.sleep(next_time - cur_time)
   -- end framecap code

   love.graphics.clear(0, 0, 0, 1)

   local progress_r = (progress_time - 0) % 255
   local progress_g = (progress_time - 100) % 255
   local progress_b = (progress_time - 200) % 255

   pixeleffect:send("progress_r", progress_r/255)
   pixeleffect:send("progress_g", progress_g/255)
   pixeleffect:send("progress_b", progress_b/255)
   love.graphics.draw(base, 0, 0, 0, scale, scale, 0, 0)
end

function load_shader()
      glsl = [[
      	     extern float progress_r;
	     extern float progress_g;
	     extern float progress_b;
	     extern Image progressmap;

             float bump(float base, float current){
		float result;
		if(current > base){
		   result = pow(abs(current - base - 1), 8);
		}
		else {
		   result = 0;
		}
	        return clamp(result, 0, 1);
             }

    	     vec4 effect(vec4 global_draw_color, Image texture, vec2 texture_coords, vec2 pixel_coords){
	        vec4 progressColor = Texel(progressmap, texture_coords);
                vec4 color = Texel(texture, texture_coords);
		float rBumpFactor = bump(progress_r, progressColor.r);
		float gBumpFactor = bump(progress_g, progressColor.g);
		float bBumpFactor = bump(progress_b, progressColor.b);
		return rBumpFactor*color + gBumpFactor*color + bBumpFactor*color;
             }
       ]]
       pixeleffect = love.graphics.newPixelEffect(glsl)
       pixeleffect:send("progressmap", progressmap)
       print(pixeleffect:getWarnings())
end