#ifndef TRANSFERMANAGER_H
#define TRANSFERMANAGER_H

#include <QObject>
#include <QString>
#include <QTcpSocket>
#include <QFile>

class TransferManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(int progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)

public:
    explicit TransferManager(QObject *parent = nullptr);
    ~TransferManager();

    // Getters
    int progress() const;
    QString statusMessage() const;

    // Callable function from QML
    Q_INVOKABLE void startTransfer(QString ip, int port, QString filePath, QString uuid, QString checksum);
    Q_INVOKABLE void cancelTransfer();
signals:
    void progressChanged();
    void statusMessageChanged();

private slots:
    // We will connect these to the QTcpSocket signals later
    void onConnected();
    void onBytesWritten(qint64 bytes);
    void onSocketError(QTcpSocket::SocketError socketError);

private:
    void setStatus(const QString &message);
    void setProgress(int value);

    // Member variables for the properties
    int m_progress;
    QString m_statusMessage;

    // Networking and File handling
    QTcpSocket *m_socket;
    QFile *m_file;
    qint64 m_totalBytesToTransfer;
    qint64 m_bytesTransferred;
    QString m_uuid;
    QString m_checksum;
};

#endif // TRANSFERMANAGER_H
