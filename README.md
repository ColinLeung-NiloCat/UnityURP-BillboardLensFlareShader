# UnityURP-BillboardLensFlareShader
Easy to use and optimized billboard lens flare shader for unity URP!

Why creating this shader?
-------------------
I need to render lens flare, and URP doesn't have it

How to use this shader in my URP project?
-------------------
 0. Copy this shader into your project
 1. Create a new material using this shader
 2. Assign any flare texture to this new material
 3. Create a new Quad GameObject in scene
 4. drag the material in step(1) into Quad's MeshRenderer's material slot
 5. make sure you have turn on "need depth texture"
 5. Done! Now this Quad GameObject should always look at camera, and will fadeout smoothly when "block" by scene objects
 
Editor environment requirement
-----------------------
- URP 7.3.1 or above
- Unity 2019.3 or above
