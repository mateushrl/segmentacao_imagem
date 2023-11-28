import cv2 as cv 
import numpy as np
import matplotlib.pyplot as plt
import numpy as np
import base64
from flask import Flask, request, jsonify

# ESPECIFICAÇÕES 
# Destinado para segmentar imagens em tons escuros

# LINKS E BIBLIOGRAFIAS
# https://docs.opencv.org/4.x/d3/db4/tutorial_py_watershed.html
    # Este link foi retirado a implementação básica do algoritmo watershed()
# Documentação da biblioteca openCv para aplicação dos demais filtros e metodos de segmentação

# LÓGICA DE FUNCIONAMENTO
# Recebimento das imagens (imagem a ser segmentada e imagem background)
# Pre processamento com remoção de ruidos
# Detecção de bordas 
# Remoção de ruídos residuais
# Identificação das regiões (background e foreground)
# Substituição do do fundo
# Pós processamento (aplicação do filtro gausiano levemente)
# Retorna a imagem com o novo fundo

app = Flask(__name__)

def  imprimeImg(img, titulo):
  plt.imshow(cv.cvtColor(img, cv.COLOR_BGR2RGB))
  plt.title(titulo)
  plt.axis('off')
  plt.show()

@app.route('/processar_imagem', methods=['POST'])
def processar_imagens():

    verde_rbg = [0,255,0]
    # Recebe as imagens em base64 e realiza o tratamento para serem lidas pela biblioteca cv2
    json_request = request.form
    imagem_original_base64 = json_request['imagem_original_base64']
    imagem_background_base64 = json_request['imagem_background_base64']

    imagem_bytes = base64.b64decode(imagem_original_base64)
    np_data = np.frombuffer(imagem_bytes, np.uint8)
    imagemOriginal = cv.imdecode(np_data, cv.IMREAD_UNCHANGED)

    imagem_bytes = base64.b64decode(imagem_background_base64)
    np_data = np.frombuffer(imagem_bytes, np.uint8)
    fundo = cv.imdecode(np_data, cv.IMREAD_UNCHANGED)

    # Ajusta o brilho e o contraste na imagem a ser segmentada
    # Dessa forma os detalhes da imagem escura ficarão mais evidentes
    alpha = 3
    beta = 2 
    img_original_ajustada = cv.convertScaleAbs(imagemOriginal, alpha=alpha, beta=beta)

    # Aplica filtro de média com o objetivo de borrar toda a imagem.
    # Dessa forma ficará mais fácil de aplicar a segmentação por bordas
    imagem_filtro_media = cv.blur(img_original_ajustada, (21,21), 0)

    # Parametros testados para somente uma imagem específica. 
    # Com esses parametros obtemos as bordas de interesse na imagem
    segmentacao_canny = cv.Canny(imagem_filtro_media,50,95)

    # Converte o modelo gerado pelo filtro de canny em uma imagem binária, com fundo
    # branco e bordas em preto
    ret, segmentacao_limiarizada = cv.threshold(segmentacao_canny, 0, 255, cv.THRESH_BINARY_INV + cv.THRESH_OTSU)
    
    # Remove ruidos residuais
    kernel = np.ones((3,3), np.uint8)
    abertura = cv.morphologyEx(segmentacao_limiarizada, cv.MORPH_OPEN,kernel, iterations = 10)

    background = cv.dilate(abertura, kernel, iterations=3)
    
    # Identificar regiões que possivelmente estarão no primeiro plano, utilizando-se da distância euclidiana
    transf_distancia = cv.distanceTransform(abertura, cv.DIST_L2,5)
    ret, foreground = cv.threshold(transf_distancia,  0.7 * transf_distancia.max(), 255, 0)
    foreground = np.uint8(foreground)
    
    unknown = cv.subtract(background, foreground)

    # Conecta o foreground e marca as regiões da imagem para aplocar o watershed
    ret, marcadores = cv.connectedComponents(foreground)
    marcadores = marcadores+1
    marcadores[unknown==255] = 0
    
    # Remove o ajuste de brilho e contraste
    img_original_ajustada = cv.convertScaleAbs(img_original_ajustada, alpha=1/alpha, beta=-beta/alpha)

    marcadores = cv.watershed(img_original_ajustada, marcadores)
    img_original_ajustada[marcadores == -1] = verde_rbg 
    
    copia_imagem_original = np.copy(img_original_ajustada)

    for i in range(2, int(ret) + 1):
        # Colore o background na cor preta 
        copia_imagem_original[marcadores == i] = verde_rbg
    # Colore as linhas dos marcadores (bordas) na cor preta
    copia_imagem_original[marcadores == -1] = verde_rbg

    # Ajusta a imagem de fundo para o mesmo tamanho da imagem segmentada
    fundo = cv.resize(fundo, (copia_imagem_original.shape[1], copia_imagem_original.shape[0]))

    # Obtem largua e altura da imagem segmentada
    altura, largura = copia_imagem_original.shape[:2]
    
    # Para cada pixel da imagem marcado com a cor verde_rbg (background), será substituido 
    # pelo pixel correspondente da imagem de fundo
    for i in range(altura):
        for j in range(largura):
            pixel = copia_imagem_original[i, j]
            if (pixel == verde_rbg).all():
                copia_imagem_original[i, j] = fundo[i,j]
    
    #imagem_final = cv.convertScaleAbs(copia_imagem_original, alpha=alpha, beta=beta)
    imagem_final = cv.GaussianBlur(copia_imagem_original, (7,7), 0)
    
    # Convertendo a imagem resultante para base64 para enviar como resposta
    retval, buffer = cv.imencode('.jpg', imagem_final)
    imagem_resultante_base64 = base64.b64encode(buffer).decode('utf-8')

    # Criar um dicionário para incluir a imagem base64 no JSON de resposta
    response_data = {
        'imagem_base64': imagem_resultante_base64
    }
    # Retorna a resposta como um JSON contendo a imagem base64

    response = jsonify(response_data)
    response.headers.add("Access-Control-Allow-Origin", "*") 
    return response

if __name__ == '__main__':
    app.run(debug=True)
