Shader "Skybox/DreliasFlatGradientSkybox"
{
	Properties
	{
		_TopColor("Top Color", Color) = (1, 0.3, 0.3, 0)
		_BottomColor("Bottom Color", Color) = (0.3, 0.3, 1, 0)
		_AngleTopColorEnd("Top Color Angle", Range(-90, 90)) = 45
		_AngleBottomColorEnd("Bottom Color Angle", Range(-90, 90)) = 0
	}
	SubShader
	{
		Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
		Cull Off ZWrite Off

		Pass
		{
			CGPROGRAM

			fixed4 _TopColor, _BottomColor;
			float _AngleTopColorEnd, _AngleBottomColorEnd;

			#pragma vertex vert
			#pragma fragment frag

			struct appdata {
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
			};


			struct v2f {
				float4 position : SV_POSITION;
				float4 screenPosition : TEXCOORD0;
			};

			v2f vert(appdata v) {
				v2f o;
				o.position = UnityObjectToClipPos(v.vertex);
				o.screenPosition = v.texcoord;
				return o;
			}

			float GetFOV()
			{
				return atan(1.0f / unity_CameraProjection._m11) * (360 / 3.14159);	// Get cam field of view
			}

			sampler2D _MainTex;
			
			fixed4 frag(v2f i, float4 screenPos : SV_POSITION) : SV_Target
			{
				/* Get cam y angle :
				   UNITY_MATRIX_V[2].y is y component of cam forward
				   -asin(UNITY_MATRIX_V[2].y) allow us to find back cam y rotation (in radians) */
				float camAngle = -asin(UNITY_MATRIX_V[2].y) * (180 / 3.14);

				/* Find vertical angle of each pixel on screen using cam angle and field of view
				   (upper pixels are cam angle + FOV/2, lower pixels are cam angle - FOV/2) */
				float pixelAngle = ((screenPos / _ScreenParams.y).y - 0.5) * GetFOV() + camAngle;

				/* Lerping to get sky color on this pixel */
				return lerp(_BottomColor, _TopColor, clamp(pixelAngle / (_AngleTopColorEnd + _AngleBottomColorEnd), 0, 1));
			}
			ENDCG
		}
	}
}