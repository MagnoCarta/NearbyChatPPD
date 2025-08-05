# Roteiro de Apresentação

Este roteiro explica como o projeto atende a cada um dos requisitos do trabalho de comunicação baseada em localização.

1. **Comunicação síncrona entre usuários online**
   - A aplicação cliente usa `WebSocketService` para manter uma conexão ativa com o broker.
   - O servidor expõe a rota `/chat/{userID}` gerenciada por `WebSocketHub`, permitindo troca em tempo real entre usuários conectados.

2. **Comunicação assíncrona para usuários offline**
   - O broker utiliza uma fila de mensagens (`InMemoryMessageQueue` ou `RedisMessageQueue`) para armazenar mensagens destinadas a usuários desconectados.

3. **Entrega de mensagens assíncronas somente quando o usuário está online**
   - Ao se conectar, o cliente consulta o `MessageStore` do broker e recebe as mensagens pendentes antes de iniciar o chat.

4. **Lista de contatos para cada usuário**
   - O modelo `Contact` e `ContactsViewModel` mantêm a relação de contatos próximos à localização atual do usuário.

5. **Informações de usuários na instanciação**
   - `User` é criado com nome, coordenadas (latitude/longitude) e status inicial.

6. **Definição de raio de comunicação**
   - `Settings` e `LocationViewModel` permitem escolher o raio de alcance para notificação e comunicação.

7. **Atualização de novos contatos ao entrarem no raio**
   - O servidor usa `LocationRegistry` para detectar usuários que entram no raio e envia atualizações via WebSocket.

8. **Atualização de localização, status e raio**
   - O cliente envia atualizações através do `APIClient` sempre que o usuário altera posição, estado ou raio.

9. **Comunicação síncrona apenas para contatos online dentro do raio**
   - `ContactsViewModel` filtra os contatos utilizando o status online e a distância calculada.

10. **Comunicação assíncrona para contatos offline ou fora do raio**
    - Mensagens destinadas a esses contatos são encaminhadas para a fila do broker e entregues quando estiverem disponíveis.

