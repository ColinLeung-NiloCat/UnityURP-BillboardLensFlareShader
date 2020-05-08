# UnityURP-BillboardLensFlare Shader(SRP batcher compatible)
Easy to use and mobile optimized billboard lens flare shader for unity URP!

BEFORE(nothing added)
![screenshot](https://i.imgur.com/gL6gQze.png)
Added only a new Quad Gamebject (material using URP/Unlit shader)
![screenshot](https://i.imgur.com/TOtySEC.png)
Added only a new Quad Gamebject (material using THIS shader)
-flare will always look it the camera!
![screenshot](https://i.imgur.com/pymZBQF.png)

Why creating this shader?
-------------------
I need to render lens flare in URP, and seems URP doesn't have lens flare anymore, so I write a new one.

How to use this shader in my URP project?
-------------------
 0. Copy this shader into your project
 1. Create a new material using this shader
 2. Assign any flare texture to this new material (flare texture's recommended import setting -> alpha = From Gray Scale)
 3. Create a new Quad GameObject in scene
 4. drag the material in step(1) into Quad's MeshRenderer's material slot
 5. make sure you have turned on "Need depth texture" in URP setting asset
 5. Done! Now this Quad GameObject should always look at the camera and will fade out smoothly when "blocked" by scene objects
 
Editor environment requirement
-----------------------
- URP 7.3.1 or above
- Unity 2019.3 or above

Hey I found a bug / I want some extra features
-----------------------
send me an issue!

Implementation Reference
-----------------------
Low Complexity, High Fidelity: The Rendering of INSIDE's optimized lens flare shader

https://youtu.be/RdN06E6Xn9E?t=3257
