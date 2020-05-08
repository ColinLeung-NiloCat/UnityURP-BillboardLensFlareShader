# UnityURP-BillboardLensFlare Shader(SRP batcher compatible)
Easy to use and mobile optimized billboard lens flare shader for unity URP!

(1) BEFORE(nothing added)
![screenshot](https://i.imgur.com/gL6gQze.png)
(2) Added only a new Quad Gamebject (material using URP/Unlit shader), with a random rotation just to prove it is working in step(3)
![screenshot](https://i.imgur.com/TOtySEC.png)
(3) only switched step(2)'s material's shader to THIS shader -> now lens flare will always look the camera(purely by shader), you DON'T need a C# script to make the quad look at the camera! Everything is just renderer and material.
![screenshot](https://i.imgur.com/pymZBQF.png)

Why creating this shader?
-------------------
I need to render lots of small lens flares in URP for mobile, and seems that URP doesn't have lens flare anymore, so I write a new one.

How to use this shader in my URP project?
-------------------
 0. Copy this shader into your project
 1. Create a new material using this shader
 2. Assign any flare texture to this new material (flare texture's recommend import setting -> alpha = From Gray Scale)
 3. Create a new Quad GameObject in scene
 4. drag the material in step(1) into Quad's MeshRenderer's material slot
 5. make sure you have turned on "Need depth texture" in URP setting asset
 5. Done! Now this Quad GameObject will always look at the camera and will fade out smoothly when "blocked" by opaque/alpha test renderers.
 
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
