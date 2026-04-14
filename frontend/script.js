const db_candidaturas = [];

function updateFileName(input) {
    const display = document.getElementById('file-name-display');
    if (input.files && input.files[0]) {
        const fileName = input.files[0].name;
        display.innerText = fileName;
        display.classList.replace('text-slate-400', 'text-sky-400');
        display.classList.add('font-bold');
        console.log("Arquivo detectado:", fileName);
    }
}

function loadExtraJobs() {
    const extraJobs = [
        { id: 'FULL-02', title: 'Full Stack Developer', loc: 'Remoto' },
        { id: 'DEV-03', title: 'DevOps Engineer', loc: 'São Paulo' },
        { id: 'INFRA-04', title: 'Analista de Infraestrutura', loc: 'Híbrido' }
    ];
    
    const grid = document.getElementById('jobs-grid');
    extraJobs.forEach(job => {
        grid.innerHTML += `
            <div class="glass-card p-6 rounded-xl border-l-4 border-purple-500 hover:bg-slate-800/50 cursor-pointer transition animate-fade-in" onclick="openJobDetail('${job.id}', '${job.title}')">
                <div class="flex justify-between items-center">
                    <div>
                        <h3 class="text-xl font-bold">${job.title}</h3>
                        <p class="text-slate-400">${job.loc} • <span class="text-purple-400">#${job.id}</span></p>
                    </div>
                    <i class="fas fa-chevron-right text-slate-600"></i>
                </div>
            </div>
        `;
    });
    document.getElementById('load-more').classList.add('hide');
}

function openJobDetail(id, title = 'Site Reliability Engineer Pleno') {
    document.getElementById('home-view').classList.add('hide');
    document.getElementById('job-detail-view').classList.remove('hide');
    document.getElementById('job-title-display').innerText = title;
    window.scrollTo(0, 0);
}

function showHome() {
    document.getElementById('job-detail-view').classList.add('hide');
    document.getElementById('home-view').classList.remove('hide');
    document.getElementById('file-name-display').innerText = "Anexar currículo";
}

function handleApplication(e) {
    e.preventDefault();
    
    const fileInput = document.getElementById('cand-cv');
    const fileName = fileInput.files[0] ? fileInput.files[0].name : "Nenhum arquivo";
    const vagaNome = document.getElementById('job-title-display').innerText;
    const candidatoNome = document.getElementById('cand-name').value;

    const candidatura = {
        vaga_id: vagaNome,
        nome: candidatoNome,
        email: document.getElementById('cand-email').value,
        salario: document.getElementById('cand-salary').value,
        arquivo_cv: fileName,
        data: new Date().toLocaleString()
    };

    
    db_candidaturas.push(candidatura);
    console.table(db_candidaturas);

    
    fetch(`http://techleap-alb-165520574.us-east-1.elb.amazonaws.com:3000/candidatar`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(candidatura)
    })
    .then(response => {
        if (response.ok) {
            
            const modal = document.getElementById('success-modal');
            const modalMsg = document.getElementById('modal-msg');
            
            modalMsg.innerHTML = `Parabéns <strong>${candidatoNome}</strong>!<br>Sua candidatura para <strong>${vagaNome}</strong> foi enviada e salva no banco de dados com sucesso!<br>CV: <em>${fileName}</em>.`;
            
            modal.classList.remove('hidden');
            e.target.reset();
            document.getElementById('file-name-display').innerText = "Anexar currículo";
        } else {
            alert("Erro ao salvar no banco de dados. Verifique o Backend.");
        }
    })
    .catch(error => {
        console.error('Erro de conexão:', error);
        alert("O Backend está offline! Rode 'docker-compose up' para testar.");
    });
}