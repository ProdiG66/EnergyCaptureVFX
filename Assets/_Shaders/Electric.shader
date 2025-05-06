Shader "Unlit/Electric"
{
    Properties
    {
        [HDR] _Color ("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            float4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float3 random3(float3 c) {
	            float j = 4096.0*sin(dot(c,float3(17.0, 59.4, 15.0)));
	            float3 r;
	            r.z = frac(512.0*j);
	            j *= .125;
	            r.x = frac(512.0*j);
	            j *= .125;
	            r.y = frac(512.0*j);
	            return r-0.5;
            }

            const float F3 =  0.3333333;
            const float G3 =  0.1666667;

            float simplex3d(float3 p) {
				float3 s = floor(p + dot(p, float3(F3,F3,F3)));
				float3 x = p - s + dot(s, float3(G3,G3,G3));
				
				float3 e = step(float3(0,0,0), x - x.yzx);
				float3 i1 = e*(1.0 - e.zxy);
				float3 i2 = 1.0 - e.zxy*(1.0 - e);
	 				
				float3 x1 = x - i1 + G3;
				float3 x2 = x - i2 + 2.0*G3;
				float3 x3 = x - 1.0 + 3.0*G3;
				
				float4 w, d;
				w.x = dot(x, x);
				w.y = dot(x1, x1);
				w.z = dot(x2, x2);
				w.w = dot(x3, x3);
				
				w = max(0.6 - w, 0.0);
				
				d.x = dot(random3(s), x);
				d.y = dot(random3(s + i1), x1);
				d.z = dot(random3(s + i2), x2);
				d.w = dot(random3(s + 1.0), x3);
				
				w *= w;
				w *= w;
				d *= w;
				
				return dot(d, float4(52,52,52,52));
			}

			float noise(float3 m) {
			    return   0.5333333*simplex3d(m)
						+0.2666667*simplex3d(2.0*m)
						+0.1333333*simplex3d(4.0*m)
						+0.0666667*simplex3d(8.0*m);
			}		

            fixed4 frag (v2f i) : SV_Target
            {
				float2 uv = i.uv;    
				uv = uv * 2. -1.;  

				float2 p = uv;
				float3 p3 = float3(p.x, p.y, _Time.x);    

				float intensity = noise(float3(p3 * 13.));
				float t = clamp((uv.x * -uv.x * 0.2) + 0.15, 0., 1.);                         
				float y = abs(intensity * -t + uv.y);
				float g = pow(y, 0.1);
				
				float3 col = float3(1.70, 1.48, 1.78);
				col = col * -g + col;

				float brightness = dot(col, float3(0.2126, 0.7152, 0.0722));
				col = brightness > 0.5 ? float3(1, 1, 1) : float3(0,0,0);

				// Multiply final color by _Color
				fixed4 fragColor = fixed4(col, col.r) * _Color;
                UNITY_APPLY_FOG(i.fogCoord, fragColor);
                return fragColor;
            }
            ENDCG
        }
    }
}
