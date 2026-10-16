import '../app_translations.dart';
import 'base.dart';

final Map<String, String> ptBr = <String, String>{
  ...buildBaseTranslations(),
  AppTranslations.appName: 'Mensageiro',
  AppTranslations.loginHeadline: 'Bem-vindo de volta às suas conversas',
  AppTranslations.loginSubtitle:
      'Faça login para continuar seus bate-papos, gerenciar contas vinculadas e ficar perto de seu pessoal.',
  AppTranslations.loginIdentifierLabel: 'E-mail ou nome de usuário',
  AppTranslations.loginIdentifierHint: 'Digite seu e-mail ou nome de usuário',
  AppTranslations.passwordLabel: 'Senha',
  AppTranslations.passwordHint: 'Digite sua senha',
  AppTranslations.rememberMe: 'Lembre-se de mim',
  AppTranslations.forgotPassword: 'Esqueceu a senha?',
  AppTranslations.signIn: 'Faça login',
  AppTranslations.createAccount: 'Criar conta',
  AppTranslations.alreadyHaveAccount: 'Já tem uma conta?',
  AppTranslations.dontHaveAccount: 'Não tem uma conta?',
  AppTranslations.registerTitle: 'Cadastre-se',
  AppTranslations.registerSubtitle:
      'Preencha os detalhes da sua conta para criar uma nova conta no Messenger.',
  AppTranslations.signUpHeadline: 'Crie sua conta no Messenger',
  AppTranslations.signUpSubtitle:
      'Participe da conversa com uma nova conta e prossiga automaticamente para a próxima etapa de configuração necessária.',
  AppTranslations.signUpToggleTitle: 'Novo aqui?',
  AppTranslations.signInToggleTitle: 'Já tem uma conta?',
  AppTranslations.signUpUsernameLabel: 'Nome de usuário',
  AppTranslations.signUpUsernameHint: 'Escolha um nome de usuário',
  AppTranslations.signUpEmailLabel: 'Endereço de e-mail',
  AppTranslations.signUpEmailHint: 'Digite seu endereço de e-mail',
  AppTranslations.signUpFirstNameLabel: 'Primeiro nome',
  AppTranslations.signUpFirstNameHint: 'Digite seu primeiro nome',
  AppTranslations.signUpLastNameLabel: 'Sobrenome',
  AppTranslations.signUpLastNameHint: 'Digite seu sobrenome',
  AppTranslations.signUpGenderLabel: 'Gênero',
  AppTranslations.signUpGenderMale: 'Masculino',
  AppTranslations.signUpGenderFemale: 'Feminino',
  AppTranslations.signUpConfirmPasswordLabel: 'Confirmar senha',
  AppTranslations.signUpConfirmPasswordHint: 'Digite novamente sua senha',
  AppTranslations.signUpUsernameRequired: 'O nome de usuário é obrigatório',
  AppTranslations.signUpUsernameTooShort:
      'O nome de usuário deve ter pelo menos 3 caracteres',
  AppTranslations.signUpEmailRequired: 'O endereço de e-mail é obrigatório',
  AppTranslations.signUpEmailInvalid: 'Insira um endereço de e-mail válido',
  AppTranslations.signUpPasswordTooShort:
      'A senha deve ter pelo menos 6 caracteres',
  AppTranslations.signUpConfirmPasswordRequired:
      'A confirmação da senha é obrigatória',
  AppTranslations.signUpPasswordsDoNotMatch: 'As senhas não coincidem',
  AppTranslations.signUpFirstNameRequired: 'O primeiro nome é obrigatório',
  AppTranslations.signUpLastNameRequired: 'O sobrenome é obrigatório',
  AppTranslations.signUpFailed: 'Não é possível criar a conta no momento',
  AppTranslations.signUpNote:
      'Após a inscrição, o Messenger irá guiá-lo automaticamente através da ativação ou de qualquer etapa de configuração necessária.',
  AppTranslations.signUpAgreementPrefix: 'Eu concordo com o',
  AppTranslations.signUpAgreementAnd: 'e',
  AppTranslations.signUpAgreementSuffix: 'antes de criar minha conta.',
  AppTranslations.signUpTermsOfUse: 'Termos de Uso',
  AppTranslations.signUpPrivacyPolicy: 'Política de Privacidade',
  AppTranslations.signUpTermsRequiredTitle: 'Aprovação necessária',
  AppTranslations.signUpTermsRequiredMessage:
      'Você deve primeiro concordar com os Termos de Uso e a Política de Privacidade.',
  AppTranslations.webViewPageTitle: 'Detalhes',
  AppTranslations.secureAccessNote:
      'Login protegido com verificação de sessão com reconhecimento de dispositivo.',
  AppTranslations.loginFooter:
      'Desenvolvido para mensagens rápidas com um fluxo de login focado e seguro.',
  AppTranslations.loginWithTimeline: 'Continuar com a conta Timeline',
  AppTranslations.loginWithTimelineSubtitle:
      'Use a conta que já está logada na Linha do Tempo.',
  AppTranslations.identifierRequired: 'E-mail ou nome de usuário é obrigatório',
  AppTranslations.passwordRequired: 'A senha é obrigatória',
  AppTranslations.loading: 'Carregando...',
  AppTranslations.homeHeadline: 'Mensagens',
  AppTranslations.homeSubtitle: 'Fique perto das pessoas de quem você gosta.',
  AppTranslations.homeWelcomeBack: 'Bem-vindo de volta, @nome',
  AppTranslations.homeSearchHint: 'Pesquisar conversas',
  AppTranslations.homeSearchEmptyTitle: 'Nenhuma conversa correspondente',
  AppTranslations.homeSearchEmptyBody:
      'Experimente outro nome ou palavra-chave para encontrar uma conversa.',
  AppTranslations.addStory: 'Adicionar história',
  AppTranslations.shareStory: 'Compartilhar história',
  AppTranslations.storyAddText: 'Adicionar texto',
  AppTranslations.storyTextHint: 'Escreva algo...',
  AppTranslations.storyMediaHint:
      'Adicione uma foto ou vídeo para compartilhar sua história.',
  AppTranslations.camera: 'Câmera',
  AppTranslations.gallery: 'Galeria',
  AppTranslations.done: 'Concluído',
  AppTranslations.replyToStory: 'Responder à história',
  AppTranslations.storyReplySent: 'Resposta da história enviada.',
  AppTranslations.storyReactionSent: 'Reação da história enviada.',
  AppTranslations.storyPublished: 'História publicada.',
  AppTranslations.storyViews: 'Visualizações',
  AppTranslations.storyViewers: 'Visualizadores de histórias',
  AppTranslations.storyReactions: 'Reações da história',
  AppTranslations.noStoryViewers: 'Ainda não há espectadores.',
  AppTranslations.noStoryReactions: 'Nenhuma reação ainda.',
  AppTranslations.unableToLoadStoryViewers:
      'Não é possível carregar os visualizadores de histórias no momento.',
  AppTranslations.unableToLoadStoryReactions:
      'Não é possível carregar as reações da história no momento.',
  AppTranslations.unableToReplyToStory:
      'Não é possível enviar a resposta da história no momento.',
  AppTranslations.unableToReactToStory:
      'Não é possível enviar a reação da história no momento.',
  AppTranslations.unableToPublishStory:
      'Não é possível publicar a história no momento.',
  AppTranslations.storiesLoadFailed: 'Falha ao carregar histórias',
  AppTranslations.storyFeatureSoon:
      'O visualizador e a publicação de histórias vêm em seguida.',
  AppTranslations.homeStoriesTitle: 'Ativo agora',
  AppTranslations.homeChatsTitle: 'Bate-papos recentes',
  AppTranslations.homeTabAll: 'Todos',
  AppTranslations.homeTabUnread: 'Não lido',
  AppTranslations.homeTabGroups: 'Grupos',
  AppTranslations.homeOnlineNow: 'on-line agora',
  AppTranslations.homeTypePlaceholder: 'Digite uma mensagem',
  AppTranslations.homeStatusActive: 'Ativo agora',
  AppTranslations.homeStatusTyping: 'Digitando...',
  AppTranslations.homeStatusSent: 'Enviado',
  AppTranslations.homeStatusDelivered: 'Entregue',
  AppTranslations.homeStatusVoice: 'Mensagem de voz',
  AppTranslations.homeStatusMuted: 'Notificações silenciadas',
  AppTranslations.homeChatsUnavailableTitle:
      'Os chats ao vivo ainda não estão prontos',
  AppTranslations.homeChatsUnavailableBody:
      'O endpoint de bate-papo do Messenger ainda está retornando uma resposta de scaffold do servidor.',
  AppTranslations.homeChatsEmptyTitle: 'Sua caixa de entrada está pronta',
  AppTranslations.homeChatsEmptyBody:
      'Inicie sua primeira conversa para ver mensagens, respostas e momentos compartilhados aparecerem aqui.',
  AppTranslations.homeChatsEmptyAction: 'Iniciar um bate-papo',
  AppTranslations.retry: 'Tentar novamente',
  AppTranslations.settingsTitle: 'Configurações',
  AppTranslations.settingsLanguage: 'Idioma',
  AppTranslations.settingsArabic: 'Árabe',
  AppTranslations.settingsEnglish: 'Inglês',
  AppTranslations.settingsFrench: 'Francês',
  AppTranslations.settingsSpanish: 'Espanhol',
  AppTranslations.settingsPortuguese: 'Português',
  AppTranslations.settingsGerman: 'Alemão',
  AppTranslations.settingsTurkish: 'Turco',
  AppTranslations.settingsDutch: 'Holandês',
  AppTranslations.settingsItalian: 'Italiano',
  AppTranslations.settingsRussian: 'Russo',
  AppTranslations.settingsRomanian: 'Romeno',
  AppTranslations.settingsPortugueseBrazil: 'Português (Brasil)',
  AppTranslations.settingsGreek: 'Grego',
  AppTranslations.settingsUkrainian: 'ucraniano',
  AppTranslations.settingsTheme: 'Tema',
  AppTranslations.settingsDarkMode: 'Modo escuro',
  AppTranslations.settingsLightMode: 'Modo claro',
  AppTranslations.settingsLanguageSheetDescription:
      'Escolha o idioma do aplicativo em uma lista limpa.',
  AppTranslations.settingsHeroDescription:
      'Gerencie o idioma, a aparência e o acesso à conta em um só lugar.',
  AppTranslations.settingsPreferencesEyebrow: 'PREFERÊNCIAS',
  AppTranslations.settingsPreferencesTitle: 'Experiência do aplicativo',
  AppTranslations.settingsAccountEyebrow: 'CONTA',
  AppTranslations.settingsAccountTitle: 'Sessão e segurança',
  AppTranslations.settingsBlockedUsers: 'Usuários bloqueados',
  AppTranslations.settingsBlockedUsersSubtitle:
      'Revise as pessoas bloqueadas e remova restrições quando necessário.',
  AppTranslations.blockedUsersTitle: 'Usuários bloqueados',
  AppTranslations.blockedUsersEmpty:
      'Nenhum usuário bloqueado foi encontrado para esta conta no momento.',
  AppTranslations.blockedUsersUnblock: 'Desbloquear',
  AppTranslations.blockedUsersUnblockTitle: 'Desbloquear usuário',
  AppTranslations.blockedUsersUnblockMessage:
      'Deseja remover este usuário da sua lista de bloqueados?',
  AppTranslations.blockedUsersUserUnblocked: 'Usuário desbloqueado com sucesso',
  AppTranslations.settingsDeleteAccount: 'Excluir conta',
  AppTranslations.settingsDeleteAccountSubtitle:
      'Remova esta conta permanentemente e apague o acesso ao Messenger.',
  AppTranslations.settingsDeleteAccountTitle: 'Excluir conta',
  AppTranslations.settingsDeleteAccountMessage:
      'Esta ação é permanente. Tem certeza de que deseja excluir sua conta?',
  AppTranslations.settingsDeleteAccountConfirm: 'Excluir conta',
  AppTranslations.settingsDeleteAccountSuccess:
      'Sua conta foi excluída com sucesso',
  AppTranslations.settingsLogoutSubtitle:
      'Sair da sessão atual neste dispositivo',
  AppTranslations.settingsLogout: 'Sair',
  AppTranslations.settingsLogoutTitle: 'Sair',
  AppTranslations.settingsLogoutMessage:
      'Tem certeza de que deseja sair do Messenger neste dispositivo?',
  AppTranslations.settingsLogoutTimelineBridgeMessage:
      'Você será desconectado apenas do Messenger. Sua sessão da Timeline permanecerá conectada neste dispositivo.',
  AppTranslations.settingsLogoutCancel: 'Cancelar',
  AppTranslations.settingsLogoutConfirm: 'Sair',
  AppTranslations.settingsLegalEyebrow: 'LEGAL',
  AppTranslations.settingsLegalTitle: 'Privacidade e termos',
  AppTranslations.settingsPrivacyPolicy: 'Política de Privacidade',
  AppTranslations.settingsPrivacyPolicySubtitle:
      'Veja como o Ukraina.co-Chat coleta, usa e protege os dados da conta.',
  AppTranslations.settingsTermsOfUse: 'Termos de Uso',
  AppTranslations.settingsTermsOfUseSubtitle:
      'Leia as regras, responsabilidades e termos de uso do Ukraina.co-Chat.',
  AppTranslations.navChats: 'Bate-papos',
  AppTranslations.navCalls: 'Chamadas',
  AppTranslations.navProfile: 'Perfil',
  AppTranslations.navSettings: 'Configurações',
  AppTranslations.composeTitle: 'Nova conversa',
  AppTranslations.composeSearchHint: 'Pesquisar amigos',
  AppTranslations.composeSelectContact: 'Selecione um amigo primeiro',
  AppTranslations.composeOpenConversation: 'Conversa aberta',
  AppTranslations.composeContactsUnavailable:
      'Os contatos aparecerão aqui assim que o endpoint estiver pronto.',
  AppTranslations.composeNoContacts: 'Nenhum contato disponível no momento.',
  AppTranslations.composeRecipientId: 'ID do usuário destinatário',
  AppTranslations.composeRecipientHint: 'Insira o ID do usuário',
  AppTranslations.composeMessage: 'Primeira mensagem',
  AppTranslations.composeMessageHint: 'Escreva sua mensagem',
  AppTranslations.composeSend: 'Enviar',
  AppTranslations.composeRecipientRequired:
      'O ID do usuário do destinatário é obrigatório',
  AppTranslations.composeMessageRequired: 'A mensagem é obrigatória',
  AppTranslations.callsPlaceholder:
      'A guia Chamadas está pronta para a próxima etapa da API.',
  AppTranslations.callsEmptyTitle: 'Nenhuma chamada ainda',
  AppTranslations.callsEmptyBody:
      'Suas chamadas de voz e vídeo recentes aparecerão aqui.',
  AppTranslations.callsIncoming: 'Entrada',
  AppTranslations.callsOutgoing: 'Saída',
  AppTranslations.callsMissed: 'Perdido',
  AppTranslations.callsDeclined: 'Recusado',
  AppTranslations.callsAnswered: 'Respondido',
  AppTranslations.callsOpenChat: 'Abrir bate-papo',
  AppTranslations.profilePlaceholder:
      'A guia Perfil é reservada para detalhes da conta e identidade.',
  AppTranslations.profileCurrentAccount: 'Conta corrente',
  AppTranslations.profileConnectedAccounts: 'Contas conectadas',
  AppTranslations.profileAddAccount: 'Adicionar conta',
  AppTranslations.profileSwitchAccount: 'Mudar',
  AppTranslations.profileRemoveAccount: 'Remover',
  AppTranslations.profileRevokeAccount: 'Revogar',
  AppTranslations.profileAccountUsername: 'Nome de usuário',
  AppTranslations.profileAccountEmail: 'E-mail',
  AppTranslations.profileAccountStatus: 'Status da conta',
  AppTranslations.profileAccountCurrent: 'Atual',
  AppTranslations.profileAccountMaster: 'Mestre',
  AppTranslations.profileNoConnectedAccounts:
      'Nenhuma conta conectada foi encontrada ainda.',
  AppTranslations.profileAddAccountTitle: 'Adicionar conta conectada',
  AppTranslations.profileAddAccountIdentifier: 'E-mail ou nome de usuário',
  AppTranslations.profileAddAccountIdentifierHint:
      'Digite o e-mail ou nome de usuário da conta vinculada',
  AppTranslations.profileAddAccountPassword: 'Senha da conta',
  AppTranslations.profileAddAccountConfirm: 'Conectar conta',
  AppTranslations.profileAddAccountSuccess:
      'Conta conectada adicionada com sucesso',
  AppTranslations.profileSwitchAccountSuccess: 'Conta trocada com sucesso',
  AppTranslations.profileRemoveAccountTitle: 'Remover conta conectada',
  AppTranslations.profileRemoveAccountMessage:
      'Tem certeza de que deseja remover esta conta conectada?',
  AppTranslations.profileRemoveAccountSuccess:
      'Conta conectada removida com sucesso',
  AppTranslations.profileRevokeAccountTitle: 'Revogar conexão da conta',
  AppTranslations.profileRevokeAccountMessage:
      'Tem certeza de que deseja revogar a conexão mestre vinculada atual?',
  AppTranslations.profileRevokeAccountSuccess:
      'Conexão de conta revogada com sucesso',
  AppTranslations.profileManageSettings: 'Abrir configurações',
  AppTranslations.profileTimelineBridgeActive:
      'A sessão de ponte da linha do tempo está ativa neste dispositivo.',
  AppTranslations.profileLinkedAccountsDisabled:
      'A troca de conta conectada está desativada para esta conta.',
  AppTranslations.profileAccountAdded: 'Conta conectada',
  AppTranslations.profileAccountEmptyField:
      'E-mail/nome de usuário e senha são obrigatórios',
  AppTranslations.chatOnlineNow: 'On-line agora',
  AppTranslations.chatSeen: 'Visto',
  AppTranslations.chatInputHint: 'Digite uma mensagem',
  AppTranslations.chatInfoTitle: 'Informações de bate-papo',
  AppTranslations.chatInfoSharedMedia: 'Mídia compartilhada',
  AppTranslations.chatInfoSettings: 'Configurações de bate-papo',
  AppTranslations.chatInfoAll: 'Todos',
  AppTranslations.chatInfoImages: 'Imagens',
  AppTranslations.chatInfoVideos: 'Vídeos',
  AppTranslations.chatInfoAudio: 'Áudio',
  AppTranslations.chatInfoFiles: 'Arquivos',
  AppTranslations.chatInfoLinks: 'Ligações',
  AppTranslations.chatInfoNoSharedMedia:
      'Nenhum conteúdo compartilhado encontrado para esta conversa.',
  AppTranslations.chatInfoOpen: 'Abrir',
  AppTranslations.chatSettingBackground: 'Plano de fundo do bate-papo',
  AppTranslations.chatSettingMute: 'Silenciar notificações',
  AppTranslations.chatSettingPin: 'Fixar bate-papo',
  AppTranslations.chatSettingBlock: 'Bloquear usuário',
  AppTranslations.chatSettingReport: 'Denunciar usuário',
  AppTranslations.chatSettingReportSubtitle:
      'Envie uma denúncia de segurança sobre esta conta.',
  AppTranslations.chatSettingDelete: 'Excluir conversa',
  AppTranslations.chatSettingApiPending:
      'Esta configuração está aguardando o endpoint de API dedicado.',
  AppTranslations.chatReportTitle: 'Denunciar usuário',
  AppTranslations.chatReportDescription:
      'Escolha o motivo desta denúncia. O Ukraina.co-Chat a enviará para a equipe de moderação analisar.',
  AppTranslations.chatReportCategoryLabel: 'Categoria da denúncia',
  AppTranslations.chatReportCategoryHint: 'Selecione um motivo',
  AppTranslations.chatReportReasonLabel: 'Detalhes adicionais',
  AppTranslations.chatReportReasonHint:
      'Adicione mais contexto para ajudar na análise desta denúncia.',
  AppTranslations.chatReportSubmit: 'Enviar denúncia',
  AppTranslations.chatReportSuccess: 'Denúncia enviada',
  AppTranslations.chatReportEmptyCategories:
      'Não há categorias de denúncia disponíveis no momento.',
  AppTranslations.chatReportCategoryRequired:
      'Selecione uma categoria de denúncia antes de continuar.',
  AppTranslations.chatReportLoadFailed:
      'Não foi possível carregar as categorias de denúncia agora.',
  AppTranslations.chatDeleteTitle: 'Excluir conversa',
  AppTranslations.chatDeleteMessage:
      'Tem certeza de que deseja excluir esta conversa?',
  AppTranslations.chatDeleteConfirm: 'Excluir',
  AppTranslations.chatDeleted: 'Conversa excluída com sucesso',
  AppTranslations.chatMessageDelete: 'Excluir mensagem',
  AppTranslations.chatMessageEdit: 'Editar mensagem',
  AppTranslations.chatMessageReply: 'Responder',
  AppTranslations.chatMessageForward: 'Avançar',
  AppTranslations.chatMessageCopy: 'Copiar',
  AppTranslations.chatStickerTitle: 'Adesivos',
  AppTranslations.chatStickerSubtitle:
      'Escolha um pacote de adesivos e envie-o instantaneamente.',
  AppTranslations.chatStickerEmpty: 'Nenhum adesivo disponível neste pacote.',
  AppTranslations.chatMessageDeleteTitle: 'Excluir mensagem',
  AppTranslations.chatMessageDeleteMessage:
      'Tem certeza de que deseja excluir esta mensagem?',
  AppTranslations.chatMessageDeleted: 'Mensagem excluída com sucesso',
  AppTranslations.chatMessageEditPending:
      'A edição de mensagens precisa de um endpoint de API dedicado.',
  AppTranslations.callVoice: 'Chamada de voz',
  AppTranslations.callVideo: 'Videochamada',
  AppTranslations.callConnecting: 'Conectando...',
  AppTranslations.callWaiting: 'Esperando a outra pessoa entrar',
  AppTranslations.callMicOff: 'Microfone desligado',
  AppTranslations.callMicOn: 'Microfone ligado',
  AppTranslations.callSpeakerOn: 'Alto-falante ligado',
  AppTranslations.callSpeakerOff: 'Alto-falante desligado',
  AppTranslations.callCameraFlip: 'Trocar câmera',
  AppTranslations.callEnd: 'Encerrar chamada',
  AppTranslations.callPermissionDenied:
      'A permissão da câmera ou do microfone foi negada.',
  AppTranslations.callAgoraDisabled:
      'A chamada Agora está desativada em settings.dart.',
  AppTranslations.callAgoraMissingAppId:
      'O ID do aplicativo Agora está faltando em settings.dart.',
  AppTranslations.callRemoteJoined: 'Conectado',
  AppTranslations.callRinging: 'Tocando...',
  AppTranslations.callNoAnswer: 'Nenhuma resposta da outra pessoa.',
  AppTranslations.callDeclined: 'A chamada foi recusada.',
  AppTranslations.callIncoming: 'Chamada recebida',
  AppTranslations.callAccept: 'Aceitar',
  AppTranslations.callDeclineAction: 'Recusar',
  AppTranslations.callRecipientBusy: 'A outra pessoa está ocupada agora.',
  AppTranslations.callRecipientOffline: 'A outra pessoa está offline.',
  AppTranslations.callCallerBusy: 'Você já tem uma chamada ativa.',
  AppTranslations.callDirectOnly:
      'As chamadas estão disponíveis apenas em conversas diretas no momento.',
  AppTranslations.callMissingConnection:
      'O servidor não retornou dados completos de conexão de chamada.',
  AppTranslations.authFlowHeadline:
      'Etapa de autenticação adicional necessária',
  AppTranslations.authFlowDescription:
      'O servidor aceitou seu login, mas a próxima etapa obrigatória é: @step',
  AppTranslations.accountBannedTitle: 'Esta conta foi banida',
  AppTranslations.accountBannedBody:
      'Sua conta do Messenger está restrita no momento e não pode usar o aplicativo no momento.',
  AppTranslations.accountBannedSupport:
      'Entre em contato com o suporte ou com o administrador do site se você acredita que isso aconteceu por engano.',
  AppTranslations.accountBannedContactSupport: 'Contate o suporte',
  AppTranslations.authActivationTitle: 'Ativação necessária',
  AppTranslations.authActivationDescription:
      'Digite o código de verificação enviado para sua conta para continuar.',
  AppTranslations.authApprovalTitle: 'Aprovação necessária',
  AppTranslations.authApprovalDescription:
      'Sua conta está aguardando aprovação antes que o Messenger possa continuar.',
  AppTranslations.authGettingStartedTitle: 'É necessário começar',
  AppTranslations.authGettingStartedDescription:
      'Sua conta precisa de mais uma etapa de configuração antes que o Messenger possa ser totalmente aberto.',
  AppTranslations.authTwoFactorTitle: 'Verificação de dois fatores',
  AppTranslations.authTwoFactorDescription:
      'Insira o código de verificação do método de dois fatores configurado.',
  AppTranslations.verificationCode: 'Código de verificação',
  AppTranslations.verificationCodeHint:
      'Digite o código exatamente como recebido',
  AppTranslations.verificationCodeRequired:
      'O código de verificação é obrigatório',
  AppTranslations.resendCode: 'Reenviar código',
  AppTranslations.verifyAndContinue: 'Verifique e continue',
  AppTranslations.activationCodeSent: 'Um novo código de ativação foi enviado.',
  AppTranslations.authUnableToLoadState:
      'Não é possível carregar seu estado de autenticação no momento.',
  AppTranslations.authUnableToVerifyCode:
      'Não é possível verificar o código no momento.',
  AppTranslations.authUnableToResendCode:
      'Não é possível reenviar o código no momento.',
  AppTranslations.backToLogin: 'Voltar ao login',
  AppTranslations.loginFailed: 'Não é possível fazer login agora',
  AppTranslations.commonConversation: 'Conversa',
  AppTranslations.commonChat: 'Bate-papo',
  AppTranslations.commonConversations: 'Conversas',
  AppTranslations.commonPeople: 'Pessoas',
  AppTranslations.commonPost: 'Postar',
  AppTranslations.commonStory: 'História',
  AppTranslations.commonReel: 'Carretel',
  AppTranslations.commonProduct: 'Produto',
  AppTranslations.commonImage: 'Imagem',
  AppTranslations.commonVideo: 'Vídeo',
  AppTranslations.commonSticker: 'Adesivo',
  AppTranslations.commonOn: 'Ligado',
  AppTranslations.commonOff: 'Desligado',
  AppTranslations.commonColors: 'Cores',
  AppTranslations.commonGradients: 'Gradientes',
  AppTranslations.commonReset: 'Redefinir',
  AppTranslations.commonTimeline: 'Linha do tempo',
  AppTranslations.timelineAppNotInstalledTitle:
      'O aplicativo Timeline não está instalado',
  AppTranslations.timelineAppNotInstalledMessage:
      'Para abrir este conteúdo, instale primeiro o aplicativo Timeline. Deseja baixá-lo agora?',
  AppTranslations.timelineAppCancelAction: 'Cancelar',
  AppTranslations.timelineAppDownloadAction: 'Baixar',
  AppTranslations.sharedPost: 'Postagem compartilhada',
  AppTranslations.sharedReel: 'Momento compartilhado',
  AppTranslations.sharePostTitle: 'Compartilhar postagem',
  AppTranslations.shareReelTitle: 'Compartilhar rolo',
  AppTranslations.shareSearchHint: 'Pesquise conversas ou pessoas',
  AppTranslations.shareEmptyTargets: 'Nenhuma conversa ou contato disponível',
  AppTranslations.profileQuickSettingsSubtitle:
      'Privacidade, notificações e preferências',
  AppTranslations.profileConnectAnother: 'Conecte outro perfil',
  AppTranslations.profileAddAccountDisabled:
      'A adição de contas está desativada',
  AppTranslations.profileIdentityEyebrow: 'IDENTIDADE',
  AppTranslations.profileSwitcherEyebrow: 'INTERRUPTOR',
  AppTranslations.profileAttachAnotherAccount:
      'Anexe outra conta para troca rápida',
  AppTranslations.profileNoEmailAttached: 'Nenhum e-mail anexado',
  AppTranslations.profileReadyToSwitch: 'Pronto para mudar',
  AppTranslations.chatPin: 'Fixar',
  AppTranslations.chatUnpin: 'Liberar',
  AppTranslations.chatConversationPinned: 'Conversa fixada',
  AppTranslations.chatConversationUnpinned: 'Conversa desafixada',
  AppTranslations.chatDirectConversation: 'Bate-papo direto',
  AppTranslations.chatGroupConversation: 'Bate-papo em grupo',
  AppTranslations.callsTotal: 'Total',
  AppTranslations.callsAll: 'Todas as chamadas',
  AppTranslations.callsHeroSubtitle:
      'Acompanhe chamadas perdidas, atendidas e videochamadas em uma visualização refinada.',
  AppTranslations.homeRecentActivity: 'Atividade recente',
  AppTranslations.chatSettingsSubtitle:
      'Gerencie notificações, estado de fixação e ações de conversa.',
  AppTranslations.chatBackgroundSubtitle:
      'Escolha um plano de fundo personalizado para esta conversa.',
  AppTranslations.chatRecordingTitle: 'Gravação',
  AppTranslations.chatRecordingBody:
      'Toque no microfone novamente para parar e enviar',
  AppTranslations.chatInvalidConversationId: 'ID de conversa inválido',
  AppTranslations.chatImageUnavailable: 'Imagem indisponível',
  AppTranslations.chatSharedItemOpenFailed:
      'Não foi possível abrir o item compartilhado',
  AppTranslations.chatVoiceUnavailable: 'Mensagem de voz indisponível',
  AppTranslations.chatVideoUnavailable: 'Vídeo indisponível',
  AppTranslations.chatReplyingTo: 'Respondendo a',
  AppTranslations.chatReplyToYourself: 'Sua mensagem',
  AppTranslations.chatReplyOriginalUnavailable:
      'Mensagem original indisponível',
  AppTranslations.chatRepliedToStory: 'Respondeu a uma história',
  AppTranslations.chatReactedToStory: 'Reagiu a uma história',
  AppTranslations.chatEditingMessage: 'Editando mensagem',
  AppTranslations.chatMessageCopied: 'Mensagem copiada',
  AppTranslations.forwardTitle: 'Encaminhar mensagem',
  AppTranslations.forwardSearchHint: 'Pesquise conversas ou pessoas',
  AppTranslations.forwardEmptyTargets: 'Nenhuma conversa ou contato disponível',
  AppTranslations.forwardPreviewTitle: 'Mensagem encaminhada',
  AppTranslations.forwardSent: 'Mensagem encaminhada com sucesso',
};
