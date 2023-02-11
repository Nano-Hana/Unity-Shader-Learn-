// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Learn/C7_4/Mask Texture" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)			//��ɫ
		_MainTex ("Main Tex", 2D) = "white" {}				//��ͼ����
		_BumpMap ("Normal Map", 2D) = "bump" {}				//��������
		_BumpScale("Bump Scale", Float) = 1.0				//�����������ֵ
		_SpecularMask ("Specular Mask", 2D) = "white" {}	//��������
		_SpecularScale ("Specular Scale", Float) = 1.0		//���̶ֳ�����ֵ
		_Specular ("Specular", Color) = (1, 1, 1, 1)		//�߹���ɫ
		_Gloss ("Gloss", Range(8.0, 256)) = 20				//�߹ⷶΧ
	}
	SubShader
	{
		Pass
		{
			Tags { "LightMode"="ForwardBase" }

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;		//
			sampler2D _BumpMap;
			float _BumpScale;
			sampler2D _SpecularMask;
			float _SpecularScale;
			fixed4 _Specular;
			float _Gloss;

			struct a2v
			{
				float4 vertex : POSITION;		//����
				float3 normal : NORMAL;			//����
				float4 tangent : TANGENT;		//����
				float4 texcoord : TEXCOORD0;	//��һ����������
			};

			struct v2f
			{
				float4 pos : SV_POSITION;		//�������
				float2 uv : TEXCOORD0;			//���uv
				float3 lightDir: TEXCOORD1;		//������շ���
				float3 viewDir : TEXCOORD2;		//����ӽǷ���
			};

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				//��ͼ->uvת�� �����ź�ƽ��
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

				//���ú���ȡrotation
				TANGENT_SPACE_ROTATION;
				//ת�������߿ռ�
				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
				o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				//���߿ռ���պ��ӽǷ����һ��
			 	fixed3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentViewDir = normalize(i.viewDir);

				//UnpackNormal��������� tex2D(����uv)�������
				fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uv));
				tangentNormal.xy *= _BumpScale;
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));	//���ڷ��߶��ǵ�λʸ����tangentNormal.z������tangentNormal.xy����ó�

				//������=���������ɫ*����ɫ
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
				//��Ȼ��=Unity��Ȼ��*������
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				//������=Unity������ɫ*������*max(0,(n*l))
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

				//Blinn-Pong�߹�ģ��specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);
				//��ʸ��=v+l��һ��
			 	fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
			 	//�����Ǹ���߹����� �������ֵ=�����������*�������
			 	fixed specularMask = tex2D(_SpecularMask, i.uv).r * _SpecularScale;
			 	//�ø߹����ּ���߹� Blinn-Pong�߹�ģ��*�߹�����
			 	fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss) * specularMask;

				//(��Ȼ��+������+�߹⣬1.0);
				return fixed4(ambient + diffuse + specular, 1.0);
			}

			ENDCG
		}
	}
	FallBack "Specular"
}
