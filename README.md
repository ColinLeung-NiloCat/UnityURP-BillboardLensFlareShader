# UnityURP-BillboardLensFlare Shader(SRP batcher compatible)
A single file billboard lens flare shader, which is easy to use and mobile optimized for unity URP!
You can copy this shader file into your URP project and use it easily. 

Shader Result
-------------------
See it in motion: https://youtu.be/owMhp5zZ1Sw
---
(1) BEFORE(nothing added)
![screenshot](https://i.imgur.com/gL6gQze.png)
(2) Added a new Quad Gamebject only, apply a random rotation just to prove that it will work with any transform.rotation in step(3)
![screenshot](https://i.imgur.com/TOtySEC.png)
(3) Now switch Quad's material's shader to THIS lens flare shader -> DONE! Now lens flare will always look at the camera(purely done by shader), you DON'T need a C# script to make the quad look at the camera! It is just a regular MeshRenderer, without any C# / particle system.
![screenshot](https://i.imgur.com/pymZBQF.png)

Shader Features
-------------------
- auto look at camera (billboard without any C# / particle system)
- smooth scene depth occlusion (use lens flare's center to do depth test)
- render on top of everything (a lens flare shader!)
- smooth fadeout when camera is too close to lens flare
- (optional)simple flicker animation inside shader, to save you time from setting up simple animation

Why creating this shader?
-------------------
I need to render lots of small lens flares in URP for mobile (gameplay enemy attack signals, battle vfx, environment light source like lamps...) and it seems that URP doesn't have any official lens flare support, so I write a new shader for this task. 
This shader's render cost is as low as possible(almost impossible for me to improve it anymore), also generic enough for anyone to use this shader in their project easily.

How to use this shader in my URP project?
-------------------
 0. Copy this shader into your URP project
 1. Create a new material using this shader (Shader path: Universal Render Pipeline -> NiloCat Extension -> BillBoard LensFlare)
 2. Assign any lens flare texture to this new material's texture slot(lens flare texture's recommend import setting -> alpha = From Gray Scale)
 3. Create a new Quad GameObject in scene
 4. drag the material in step(1) into Quad's MeshRenderer's material slot
 5. make sure you have turned on "Need depth texture" in URP setting asset
 5. Done! Now this Quad GameObject will always look at the camera and will fade out smoothly when the lens flare's center was "blocked" by opaque/alpha test renderers.

Requirement when using this shader
-------------------
- Forward rendering in URP
- _CameraDepthTexture is already rendering by unity (toggle on DepthTexture in your Universal Render Pipeline Asset)

FAQ: My lens flare texture doesn't have an alpha channel, and setting my texture's import setting's alpha = "From Gray Scale" is still not looking correct...What should I do?
-----------------------
try turn OFF "_UsePreMultiplyAlpha" in the material's setting, now shader will only consider RGB in your lens flare texture, and add it directly to screen.

FAQ: I snap my lens flare quad onto a lamp renderer's vertex, now this lens flare is occluded randomly, what should I do?
-----------------------
drag "_DepthOcclusionTestZBias" to a negative number (e.g. -0.1), which makes the DepthOcclusionTest easier to pass, hence more stable.

FAQ: Can I use it for the particle system?
-----------------------
NO, this shader requires object space mesh position data, particle system will break it. To make it works for the particle system, both the particle system and this shader must work together to make it works, which is not included in this shader for simplicity reason.

FAQ: Is this shader optimized for mobile?
-------------------
This shader is SRP batcher compatible, so you can put lots of lens flares in scene without hurting CPU performance too much(even all lens flares use different materials).

Also, this shader moved almost all calculations from fragment shader to vertex shader, so you can put lots of lens flares in scene without hurting GPU performance too much, as long as they are small and don't overlap with each other(overdraw).

Editor environment requirement
-----------------------
- URP 7.3.1 or above
- Unity 2019.3 or above

Hey, I found a bug! / I want some critical features!
-----------------------
send me an issue using GitHub! (don't send it to my email, I may miss it)

Implementation Reference
-----------------------
Low Complexity, High Fidelity: The Rendering of INSIDE's optimized lens flare shader

https://youtu.be/RdN06E6Xn9E?t=3257

credits
-----------------------
model creator in demo images - https://i-fox.club/pcr/
