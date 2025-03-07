import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:intl/intl.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../flutter_chat_ui.dart';
import '../models/emoji_enlargement_behavior.dart';
import '../util.dart';
import 'file_message.dart';
import 'image_message.dart';
import 'inherited_chat_theme.dart';
import 'inherited_user.dart';
import 'text_message.dart';

/// Base widget for all message types in the chat. Renders bubbles around
/// messages and status. Sets maximum width for a message for
/// a nice look on larger screens.
class Message extends StatelessWidget {
  /// Creates a particular message from any message type
  const Message({
    Key? key,
    this.bubbleBuilder,
    this.customMessageBuilder,
    required this.emojiEnlargementBehavior,
    this.fileMessageBuilder,
    required this.hideBackgroundOnEmojiMessages,
    this.imageMessageBuilder,
    required this.message,
    // required this.messageStatus,
    this.messageRendering,
    required this.messageWidth,
    this.onAvatarTap,
    this.onMessageDoubleTap,
    this.onMessageLongPress,
    this.onMessageStatusLongPress,
    this.onMessageStatusTap,
    this.onMessageTap,
    this.onMessageVisibilityChanged,
    this.onPreviewDataFetched,
    required this.roundBorder,
    required this.showAvatar,
    required this.showName,
    required this.showStatus,
    required this.showUserAvatars,
    this.textMessageBuilder,
    required this.usePreviewData,
    this.dateFormat,
    this.dateLocale,
    this.timeFormat,
  }) : super(key: key);

  /// Customize the default bubble using this function. `child` is a content
  /// you should render inside your bubble, `message` is a current message
  /// (contains `author` inside) and `nextMessageInGroup` allows you to see
  /// if the message is a part of a group (messages are grouped when written
  /// in quick succession by the same author)
  final Widget Function(
    Widget child, {
    required types.Message message,
    required bool nextMessageInGroup,
  })? bubbleBuilder;

  /// Build a custom message inside predefined bubble
  final Widget Function(types.CustomMessage, {required int messageWidth})?
      customMessageBuilder;

  /// Controls the enlargement behavior of the emojis in the
  /// [types.TextMessage].
  /// Defaults to [EmojiEnlargementBehavior.multi].
  final EmojiEnlargementBehavior emojiEnlargementBehavior;

  /// Build a file message inside predefined bubble
  final Widget Function(types.FileMessage, {required int messageWidth})?
      fileMessageBuilder;

  /// Hide background for messages containing only emojis.
  final bool hideBackgroundOnEmojiMessages;

  /// Build an image message inside predefined bubble
  final Widget Function(types.ImageMessage, {required int messageWidth})?
      imageMessageBuilder;

  /// Any message type
  final types.Message message;

  final Stream<List<types.Status>> Function(types.Message) messageStatus;

  /// returns message which populating in screen
  final Function(types.Message, types.StatusType?)? messageRendering;

  /// Maximum message width
  final int messageWidth;

  // Called when uses taps on an avatar
  final void Function(types.User)? onAvatarTap;

  /// Called when user double taps on any message
  final void Function(BuildContext context, types.Message)? onMessageDoubleTap;

  /// Called when user makes a long press on any message
  final void Function(BuildContext context, types.Message)? onMessageLongPress;

  /// Called when user makes a long press on status icon in any message
  final void Function(BuildContext context, types.Message)?
      onMessageStatusLongPress;

  /// Called when user taps on status icon in any message
  final void Function(BuildContext context, types.Message)? onMessageStatusTap;

  /// Called when user taps on any message
  final void Function(BuildContext context, types.Message)? onMessageTap;

  /// Called when the message's visibility changes
  final void Function(types.Message, bool visible)? onMessageVisibilityChanged;

  /// See [TextMessage.onPreviewDataFetched]
  final void Function(types.TextMessage, types.PreviewData)?
      onPreviewDataFetched;

  /// Rounds border of the message to visually group messages together.
  final bool roundBorder;

  /// Show user avatar for the received message. Useful for a group chat.
  final bool showAvatar;

  /// See [TextMessage.showName]
  final bool showName;

  /// Show message's status
  final bool showStatus;

  /// Show user avatars for received messages. Useful for a group chat.
  final bool showUserAvatars;

  final DateFormat? dateFormat;
  final String? dateLocale;
  final DateFormat? timeFormat;

  /// Build a text message inside predefined bubble.
  final Widget Function(
    types.TextMessage, {
    required int messageWidth,
    required bool showName,
  })? textMessageBuilder;

  /// See [TextMessage.usePreviewData]
  final bool usePreviewData;

  Widget _avatarBuilder(BuildContext context) {
    final color = getUserAvatarNameColor(
      message.author,
      InheritedChatTheme.of(context).theme.userAvatarNameColors,
    );
    final hasImage = message.author.imageUrl != null;
    final initials = getUserInitials(message.author);

    return showAvatar
        ? Container(
            margin: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onAvatarTap?.call(message.author),
              child: CircleAvatar(
                backgroundColor: hasImage
                    ? InheritedChatTheme.of(context)
                        .theme
                        .userAvatarImageBackgroundColor
                    : color,
                backgroundImage:
                    hasImage ? NetworkImage(message.author.imageUrl!) : null,
                radius: 16,
                child: !hasImage
                    ? Text(
                        initials,
                        style: InheritedChatTheme.of(context)
                            .theme
                            .userAvatarTextStyle,
                      )
                    : null,
              ),
            ),
          )
        : const SizedBox(width: 40);
  }

  Widget _bubbleBuilder(
    BuildContext context,
    BorderRadius borderRadius,
    bool currentUserIsAuthor,
    bool enlargeEmojis,
  ) {
    return Column(
        crossAxisAlignment: currentUserIsAuthor
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
      children: [
        bubbleBuilder != null
            ? bubbleBuilder!(
                _messageBuilder(),
                message: message,
                nextMessageInGroup: roundBorder,
              )
            : enlargeEmojis && hideBackgroundOnEmojiMessages
                ? _messageBuilder()
                : Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      color: !currentUserIsAuthor ||
                              message.type == types.MessageType.image
                          ? InheritedChatTheme.of(context).theme.secondaryColor
                          : InheritedChatTheme.of(context).theme.primaryColor,
                    ),
                    child: ClipRRect(
                      borderRadius: borderRadius,
                      child: _messageBuilder(),
                    ),
                  ),
        // const SizedBox(height: 2,),
        // Row(
        //   crossAxisAlignment: CrossAxisAlignment.end,
        //   mainAxisAlignment: MainAxisAlignment.end,
        //   mainAxisSize: MainAxisSize.min,
        //   children: [
        //     Text(
        //       messageTime(
        //         DateTime.fromMillisecondsSinceEpoch(message.createdAt!),
        //         dateLocale: dateLocale,
        //         timeFormat: timeFormat,
        //       ),
        //       textAlign: TextAlign.end,
        //       style: InheritedChatTheme.of(context).theme.messageTimeTextStyle,
        //     ),
        //     const SizedBox(width: 8,),
        //   ],
        // ),
        const SizedBox(height: 4,),
      ],
    );
  }


  Widget _messageBuilder() {
    switch (message.type) {
      case types.MessageType.custom:
        final customMessage = message as types.CustomMessage;
        return customMessageBuilder != null
            ? customMessageBuilder!(customMessage, messageWidth: messageWidth)
            : const SizedBox();
      case types.MessageType.file:
        final fileMessage = message as types.FileMessage;
        return fileMessageBuilder != null
            ? fileMessageBuilder!(fileMessage, messageWidth: messageWidth)
            : FileMessage(message: fileMessage);
      case types.MessageType.image:
        final imageMessage = message as types.ImageMessage;
        return imageMessageBuilder != null
            ? imageMessageBuilder!(imageMessage, messageWidth: messageWidth)
            : ImageMessage(message: imageMessage, messageWidth: messageWidth);
      case types.MessageType.text:
        final textMessage = message as types.TextMessage;
        return textMessageBuilder != null
            ? textMessageBuilder!(
                textMessage,
                messageWidth: messageWidth,
                showName: showName,
              )
            : TextMessage(
                emojiEnlargementBehavior: emojiEnlargementBehavior,
                hideBackgroundOnEmojiMessages: hideBackgroundOnEmojiMessages,
                message: textMessage,
                onPreviewDataFetched: onPreviewDataFetched,
                showName: showName,
                usePreviewData: usePreviewData,
              );
      default:
        return const SizedBox();
    }
  }

  types.StatusType? calculateStatus(snapshot) {
    List<types.Status> statusList = snapshot.data!;
    int count = 100;
    for (var status in statusList) {
      types.StatusType? type = status.status;
      if (count > 0 && type == types.StatusType.error) {
        count = 1;
      } else if (count > 1 && type == types.StatusType.sending) {
        count = 2;
      } else if (count > 2 && type == types.StatusType.sent) {
        count = 3;
      } else if (count > 3 && type == types.StatusType.delivered) {
        count = 4;
      } else if (count > 4 && type == types.StatusType.seen) {
        count = 5;
      }
    }

    if (count == 1) {
      return types.StatusType.error;
    } else if (count == 2) {
      return types.StatusType.sending;
    } else if (count == 3) {
      return types.StatusType.sent;
    } else if (count == 3) {
      return types.StatusType.delivered;
    } else if (count == 4) {
      return types.StatusType.seen;
    }

    return null;
  }

  Widget _statusBuilder(BuildContext context ) { //, types.StatusType? latestStatus
    switch (message.status) {
      case types.StatusType.delivered:
        return InheritedChatTheme.of(context).theme.deliveredIcon != null
            ? InheritedChatTheme.of(context).theme.deliveredIcon!
            : Image.asset(
                'assets/icon-delivered.png',
                color: InheritedChatTheme.of(context).theme.deliveredMessageIconColor,
                package: 'flutter_chat_ui',
              );
      case types.StatusType.sent:
        return InheritedChatTheme.of(context).theme.sentIcon != null
            ? InheritedChatTheme.of(context).theme.sentIcon!
            : Image.asset(
                'assets/icon-delivered.png',
                color: InheritedChatTheme.of(context).theme.sentMessageIconColor,
                package: 'flutter_chat_ui',
              );
      case types.StatusType.error:
        return InheritedChatTheme.of(context).theme.errorIcon != null
            ? InheritedChatTheme.of(context).theme.errorIcon!
            : Image.asset(
                'assets/icon-error.png',
                color: InheritedChatTheme.of(context).theme.errorColor,
                package: 'flutter_chat_ui',
              );
      case types.StatusType.seen:
        return InheritedChatTheme.of(context).theme.seenIcon != null
            ? InheritedChatTheme.of(context).theme.seenIcon!
            : Image.asset(
                'assets/icon-seen.png',
                color: InheritedChatTheme.of(context).theme.seenMessageIconColor,
                package: 'flutter_chat_ui',
              );
      case types.StatusType.sending:
        return InheritedChatTheme.of(context).theme.sendingIcon != null
            ? InheritedChatTheme.of(context).theme.sendingIcon!
            : Center(
                child: SizedBox(
                  height: 10,
                  width: 10,
                  child: CircularProgressIndicator(
                    backgroundColor: Colors.transparent,
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      InheritedChatTheme.of(context).theme.sendingMessageIconColor!,
                    ),
                  ),
                ),
              );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    final _user = InheritedUser.of(context).user;
    final _currentUserIsAuthor = _user.id == message.author.id;
    final _enlargeEmojis =
        emojiEnlargementBehavior != EmojiEnlargementBehavior.never &&
            message is types.TextMessage &&
            isConsistsOfEmojis(
                emojiEnlargementBehavior, message as types.TextMessage);
    final _messageBorderRadius =
        InheritedChatTheme.of(context).theme.messageBorderRadius;
    final _borderRadius = BorderRadius.only(
      bottomLeft: Radius.circular(
        _currentUserIsAuthor || roundBorder ? _messageBorderRadius : 0,
      ),
      bottomRight: Radius.circular(_currentUserIsAuthor
          ? roundBorder
              ? _messageBorderRadius
              : 0
          : _messageBorderRadius),
      topLeft: Radius.circular(_messageBorderRadius),
      topRight: Radius.circular(_messageBorderRadius),
    );

    return Container(
      alignment:
          _currentUserIsAuthor ? Alignment.centerRight : Alignment.centerLeft,
      margin: const EdgeInsets.only(
        bottom: 4,
        left: 20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_currentUserIsAuthor && showUserAvatars) _avatarBuilder(context),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: messageWidth.toDouble(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onDoubleTap: () => onMessageDoubleTap?.call(context, message),
                  onLongPress: () => onMessageLongPress?.call(context, message),
                  onTap: () => onMessageTap?.call(context, message),
                  child: onMessageVisibilityChanged != null
                      ? VisibilityDetector(
                          key: Key(message.id),
                          onVisibilityChanged: (visibilityInfo) =>
                              onMessageVisibilityChanged!(message,
                                  visibilityInfo.visibleFraction > 0.1),
                          child: _bubbleBuilder(
                            context,
                            _borderRadius,
                            _currentUserIsAuthor,
                            _enlargeEmojis,
                          ),
                        )
                      : _bubbleBuilder(
                          context,
                          _borderRadius,
                          _currentUserIsAuthor,
                          _enlargeEmojis,
                        ),
                ),
              ],
            ),
          ),
          // if (_currentUserIsAuthor)
          Padding(
            padding: _currentUserIsAuthor
                ? InheritedChatTheme.of(context).theme.statusIconPadding
                : const EdgeInsets.all(0),
            child: GestureDetector(
              onLongPress: () =>
                  onMessageStatusLongPress?.call(context, message),
              onTap: () => onMessageStatusTap?.call(context, message),
              child: _statusBuilder(context),
              // child: StreamBuilder<List<types.Status>>(
              //   initialData: const [],
              //   stream: messageStatus(message),
              //   builder: (context, snapshot) {
              //     if (!snapshot.hasData || snapshot.data!.isEmpty) {
              //       return const SizedBox();
              //     }
              //     types.StatusType? latestStatus = calculateStatus(snapshot);
              //
              //     if (messageRendering != null) {
              //       messageRendering!(message, latestStatus);
              //     }
              //
              //     if (!_currentUserIsAuthor || !showStatus) {
              //       return const SizedBox();
              //     }
              //
              //     return _statusBuilder(context, latestStatus);
              //   },
              // ),
            ),
          ),
        ],
      ),
    );
  }
}
