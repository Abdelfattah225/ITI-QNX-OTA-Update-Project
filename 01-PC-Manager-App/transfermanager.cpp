#include "transfermanager.h"
#include <QCryptographicHash> // Required for SHA-256

// Constructor
TransferManager::TransferManager(QObject *parent)
    : QObject(parent), m_progress{0}, m_statusMessage{"Ready"}
{
    m_socket = new QTcpSocket(this);
    m_file = new QFile(this);
}

// Destructor
TransferManager::~TransferManager() {
    if (m_file->isOpen()) m_file->close();
}

int TransferManager::progress() const {
    return m_progress;
}

QString TransferManager::statusMessage() const {
    return m_statusMessage;
}

void TransferManager::setStatus(const QString &message) {
    if(m_statusMessage != message){
        m_statusMessage = message;
        emit statusMessageChanged();
    }
}

void TransferManager::setProgress(int value) {
    if(m_progress != value){
        m_progress = value;
        emit progressChanged();
    }
}

void TransferManager::startTransfer(QString ip, int port, QString filePath, QString uuid, QString checksum){
    // 1. Clean path
    filePath = filePath.replace("file://", "");

    // 2. Open file
    m_file->setFileName(filePath);
    if(!m_file->open(QIODevice::ReadOnly)){
        setStatus("Error: Cannot open file");
        return;
    }

    // // 3. Calculate SHA-256 Checksum BEFORE starting the transfer
    // setStatus("Calculating Hash...");
    // QCryptographicHash hash(QCryptographicHash::Sha256);
    // if (hash.addData(m_file)) {
    //     m_checksum = hash.result().toHex();
    // } else {
    //     m_checksum = "NONE";
    // }
    // // Very important: Rewind the file back to the beginning so we can read it to send!
    // m_file->seek(0);

    // 4. Setup tracking variables
    m_totalBytesToTransfer = m_file->size();
    m_bytesTransferred = 0;
    m_uuid = uuid;

    // Check if the user left the hash field empty
    if (checksum.isEmpty()) {
        m_checksum = "NO_CHECKSUM_PROVIDED";
    } else {
        m_checksum = checksum;
    }

    // 5. Setup the socket signals (Note: removed the '()' from the slot names)
    connect(m_socket, &QTcpSocket::connected, this, &TransferManager::onConnected);
    connect(m_socket, &QTcpSocket::bytesWritten, this, &TransferManager::onBytesWritten);

    // 6. Update UI and Connect
    setStatus("Connecting to " + ip + "...");
    setProgress(0);
    m_socket->connectToHost(ip, port);
}

void TransferManager::onConnected() {
    setStatus("Connected! Sending header...");

    // Prepare a header string: "UUID|FILESIZE|CHECKSUM\n"
    QString header = m_uuid + "|" + QString::number(m_totalBytesToTransfer) + "|" + m_checksum + "\n";

    // Send header
    m_socket->write(header.toUtf8());

    // Kick off the file transfer by reading the first 64KB chunk
    QByteArray firstChunk = m_file->read(64 * 1024); // 64 KB
    m_socket->write(firstChunk);

    setStatus("Transferring image...");
}

void TransferManager::onBytesWritten(qint64 bytes) {
    // 1. Update our tracker
    m_bytesTransferred += bytes;

    // 2 & 3. Calculate percentage and update UI
    if (m_totalBytesToTransfer > 0) {
        int percent = (m_bytesTransferred * 100) / m_totalBytesToTransfer;
        if (percent > 100) percent = 100;
        setProgress(percent);
    }

    // 4. Check if we are completely done
    if (m_bytesTransferred >= m_totalBytesToTransfer) {
        setStatus("Deployment complete");
        m_file->close();
        m_socket->disconnectFromHost();
        m_socket->disconnect();
        return;
    }

    // 5. If not done, read and send the next chunk
    QByteArray nextChunk = m_file->read(64 * 1024); // 64 KB
    if (!nextChunk.isEmpty()) {
        m_socket->write(nextChunk);
    }
}

void TransferManager::onSocketError(QTcpSocket::SocketError socketError) {
    setStatus("Socket Error: " + m_socket->errorString());
    if (m_file->isOpen()) m_file->close();
    m_socket->disconnect();
}

void TransferManager::cancelTransfer() {
    // If the socket is currently doing something, kill it instantly
    if (m_socket->state() == QAbstractSocket::ConnectedState || m_socket->state() == QAbstractSocket::ConnectingState) {
        m_socket->disconnect(); // Stop the bytesWritten loop from firing
        m_socket->abort();      // Instantly kill the network connection
    }

    // Close the file so it's not locked by the OS
    if (m_file->isOpen()) {
        m_file->close();
    }

    // Update the UI
    setStatus("Transfer cancelled by user");
    setProgress(0);
}

