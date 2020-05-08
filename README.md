# UnityURP-BillboardLensFlare Shader(SRP batcher compatible)
Easy to use and optimized billboard lens flare shader for unity URP!

Why creating this shader?
-------------------
I need to render lens flare in URP, and seems URP doesn't have lens flare

How to use this shader in my URP project?
-------------------
 0. Copy this shader into your project
 1. Create a new material using this shader
 2. Assign any flare texture to this new material (recommend texture's import setting, alpha = From Gray Scale)
 3. Create a new Quad GameObject in scene
 4. drag the material in step(1) into Quad's MeshRenderer's material slot
 5. make sure you have turn on "need depth texture" in URP setting asset
 5. Done! Now this Quad GameObject should always look at camera, and will fadeout smoothly when "blocked" by scene objects
 
Editor environment requirement
-----------------------
- URP 7.3.1 or above
- Unity 2019.3 or above

Hey I found a bug / I want some extra features
-----------------------
send me an issue!
